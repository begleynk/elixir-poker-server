defmodule Poker.Game.State do
  alias Poker.{Game, Deck}
  defstruct [
    id: nil,
    players: [],
    small_blind: nil, 
    big_blind: nil, 
    positions: [],
    next_action: nil,
    phase: :setup,
    event_store: Game.EventStore.new,
    pot: 0,
    active_bets: Map.new,
    hand_values: %{},
    pocket_cards: %{},
    community_cards: [],
    deck: Deck.new,
    winner: nil
  ]

  def new(id: id, small_blind: sb, big_blind: bb, players: players) do
    %Game.State{ id: id, small_blind: sb, big_blind: bb, players: players }
    |> build_positions
    |> set_first_action
  end

  def handle_action(%Game.State{ next_action: %Game.NextAction{ player: next }}, %Game.Action{ player: other }) when next != other do
    {:error, :out_of_turn}
  end

  def handle_action(%Game.State{ next_action: %Game.NextAction{ to_call: to_call }}, %Game.Action{ type: :call, amount: amount }) when to_call != amount do
    {:error, :invalid_call}
  end

  def handle_action(state, %Game.Action{} = action) do
    if Enum.any?(state.next_action.actions, &(&1 == action.type)) do
      update_with_event(state, Game.Event.new(action))
    else
      {:error, :invalid_action}
    end
  end

  defp update_with_event(state, %Game.Event{} = event) do
    state
    |> save_event(event)
    |> recalculate_bets
    |> maybe_move_to_next_phase
    |> determine_next_action
    |> check_for_winner
  end

  defp maybe_move_to_next_phase(%Game.State{ phase: :setup, active_bets: bets } = state) do
    if length(bets |> Map.to_list) == 2 && 
       bets[player_in_position(state, :small_blind)] == state.small_blind &&
       bets[player_in_position(state, :big_blind)] == state.big_blind do

      state |> move_to_phase(:preflop)
    else
      state
    end
  end

  defp maybe_move_to_next_phase(%Game.State{ phase: current_phase } = state) do
    if state |> everyone_has_acted_in_phase?(current_phase) do
      state |> move_to_phase(phase_after(current_phase))
    else
      state
    end
  end

  defp check_for_winner(%Game.State{ phase: :showdown } = state) do
    %Game.State{ state | 
      winner: Game.Winner.determine(state)
    }
  end

  defp check_for_winner(state) do
    if only_one_player_left?(state) do
      %Game.State{ state | 
        winner: state.positions 
                |> Enum.find(fn({_,_,status}) -> status == :playing end) 
                |> (fn({_,pl,_}) -> pl end).()
      }
    else
      state
    end
  end

  defp everyone_has_acted_in_phase?(state, phase) do
    state |> Game.EventParser.everyone_has_acted_in_phase?(phase)
  end

  defp move_to_phase(state, new_phase) do
    case new_phase do
      :preflop -> 
        {new_deck, pocket_cards} = draw_pocket_cards(state.deck, state.players)
        %Game.State{ state | 
          event_store: Game.EventStore.add_event(state.event_store, Game.Event.phase_transition(:preflop)),
          phase: :preflop,
          pocket_cards: pocket_cards,
          deck: new_deck
        }
      :flop -> 
        {:ok, flop_cards, new_deck} = Poker.Deck.draw_cards(state.deck, 3)
        %Game.State{ state | 
          event_store: Game.EventStore.add_event(state.event_store, Game.Event.phase_transition(:flop)),
          phase: :flop,
          community_cards: flop_cards,
          active_bets: %{},
          hand_values: recalculate_hand_values(state.players, flop_cards, state.pocket_cards),
          deck: new_deck
        }
      :turn -> 
        {:ok, turn_card, new_deck} = Poker.Deck.draw_card(state.deck)
        %Game.State{ state | 
          event_store: Game.EventStore.add_event(state.event_store, Game.Event.phase_transition(:turn)),
          phase: :turn,
          community_cards: [turn_card | state.community_cards],
          hand_values: recalculate_hand_values(state.players, [turn_card | state.community_cards], state.pocket_cards),
          active_bets: %{},
          deck: new_deck
        }
      :river -> 
        {:ok, river_card, new_deck} = Poker.Deck.draw_card(state.deck)
        %Game.State{ state | 
          event_store: Game.EventStore.add_event(state.event_store, Game.Event.phase_transition(:river)),
          phase: :river,
          community_cards: [river_card | state.community_cards],
          hand_values: recalculate_hand_values(state.players, [river_card | state.community_cards], state.pocket_cards),
          active_bets: %{},
          deck: new_deck
        }
      :showdown ->
        %Game.State{ state | 
          event_store: Game.EventStore.add_event(state.event_store, Game.Event.phase_transition(:showdown)),
          phase: :showdown,
          active_bets: %{},
        }
    end
  end

  defp determine_next_action(%Game.State{ phase: :setup } = state) do
    %Game.State{ state |
      next_action: %Game.NextAction{
        player: player_in_position(state, :big_blind),
        type: :call_blind,
        actions: [:call, :sit_out],
        to_call: state.big_blind
      }
    }
  end

  defp determine_next_action(%Game.State{ phase: :preflop} = state) do
    last_event = Game.EventStore.last_event(state.event_store)

    cond do 
      only_one_player_left?(state) ->
        %Game.State{ state | next_action: nil }

      last_event.type == :phase_transition -> 
        next_to_act = active_player_after(state, :big_blind) # Preflop the player after BB goes first
        %Game.State{ state |
          next_action: %Game.NextAction{
            player: next_to_act,
            type: :call_bet,
            actions: [:call, :raise, :fold],
            to_call: state.big_blind - amount_bet_by(state, next_to_act) 
          }
        }

      true ->
        %Game.State{ state | 
          next_action: %Game.NextAction{ 
            player: active_player_after(state, last_event.player), 
            type: :call_bet 
          } |> determine_action_details(state)
        }
    end
  end

  defp determine_next_action(%Game.State{ phase: :showdown } = state) do
    %Game.State{ state | next_action: nil }
  end

  defp determine_next_action(%Game.State{} = state) do
    last_event = Game.EventStore.last_event(state.event_store)

    cond do
      only_one_player_left?(state) ->
        %Game.State{ state | next_action: nil }

      last_event.type == :phase_transition -> 
        next_to_act = 
        %Game.State{ state |
          next_action: %Game.NextAction{
            player: player_in_position(state, :small_blind),
            type: :regular_action,
            actions: [:check, :bet, :fold]
          }
        }
        
      true ->
        next_action = 
          %Game.NextAction{ player: active_player_after(state, last_event.player), type: :call_bet } 
          |> determine_action_details(state)

        %Game.State{ state | next_action: next_action}
    end
  end

  defp determine_action_details(%Game.NextAction{} = action, state) do
    to_call = highest_bet(state) - amount_bet_by(state, action.player)

    if to_call == 0 do
      %Game.NextAction{ action | to_call: 0, actions: [:check, :raise, :fold] }
    else
      %Game.NextAction{ action | to_call: to_call, actions: [:call, :raise, :fold] }
    end
  end

  defp only_one_player_left?(state) do
    1 == state.positions |> Enum.count(fn({_,_,status}) -> status == :playing end)
  end

  defp recalculate_bets(state) do
    last_event =  Game.EventStore.last_event(state.event_store)

    case last_event.type do
      :phase_transition -> 
        state
      :check -> 
        state
      :fold -> 
        %Game.State{ state | 
          positions: set_player_status(state.positions, last_event.player, :folded)
        }
      _ ->
        %Game.State{ state | 
          pot: state.pot + last_event.amount,
          active_bets: update_bets(state.active_bets, last_event) 
        }
    end
  end

  defp update_bets(bets, event) do
    Map.update(bets, event.player, event.amount, fn(_) -> event.amount end)
  end

  defp save_event(state, event) do
    %Game.State{ state | 
      event_store: state.event_store |> Game.EventStore.add_event(event)
    }
  end

  defp set_first_action(state) do
    %Game.State{ state | 
      next_action: %Game.NextAction{
        type: :call_blind,
        player: state |> player_in_position(:small_blind),
        to_call: state.small_blind,
        actions: [:call, :sit_out]
      }
    }
  end

  defp player_in_position(state, position) do
    {_, player, _} = Enum.find(state.positions, fn({pos, _player, _status}) ->
      pos == position 
    end)

    player
  end

  defp position_of(state, player) do
    {position, _, _} = Enum.find(state.positions, fn({_pos, p, _status}) ->
      p == player
    end)

    position
  end

  defp active_player_after(%Game.State{ positions: positions }, position) when is_atom(position) do
    active_players_after_position = 
      positions
      |> rotate_until_at_front(position)
      |> Enum.filter(fn({pos,_,status}) -> position == pos || status == :playing end)
      |> Enum.map(fn({_, id,_}) -> id end)

    case active_players_after_position do
      [_only_one_player] -> raise "We should probably win now?"
      [_, second | _rest] -> second
    end
  end

  defp active_player_after(state, player) do
    active_player_after(state, position_of(state, player))
  end
  
  defp rotate_until_at_front([{position, _, _} | _rest] = list, position) do
    list
  end

  defp rotate_until_at_front([p | rest], position) do
    rotate_until_at_front(rest ++ [p], position)
  end

  defp highest_bet(state) do
    case state.active_bets |> Map.to_list do
      []   -> 0
      list -> list
              |> Enum.map(fn({_, amount}) -> amount end)
              |> Enum.max
    end
  end

  defp build_positions(%Game.State{players: players} = state) do
    last_position = length(players) - 1

    positions = 
      players
      |> Stream.with_index
      |> Enum.map(fn({player, index}) -> 
        case index do
          0 -> {:small_blind, player, :playing} 
          1 -> {:big_blind, player, :playing} 
          ^last_position -> {:button, player, :playing}
          pos -> {(pos + 1) |> Integer.to_string |> String.to_atom, player, :playing}
        end
      end)

    %Game.State{state | positions: positions}
  end

  defp recalculate_hand_values(players, community_cards, pocket_cards) do
    players
    |> Enum.map(fn(p) -> 
         {pc1, pc2} = pocket_cards[p]
         {p, Poker.HandRank.determine_best_hand(community_cards ++ [pc1, pc2])}
       end)
    |> Enum.into(Map.new)
  end

  defp draw_pocket_cards(deck, players) do
    Enum.reduce(players, {deck, Map.new}, fn(id, {the_deck, hands}) ->
      {:ok, [card1, card2], new_deck} = Deck.draw_cards(the_deck, 2)
      {new_deck, Map.put(hands, id, {card1, card2})}
    end)
  end

  defp set_player_status(positions, player, new_status) do
    positions
    |> Enum.map(fn({pos, pl, _status} = data) ->
      if pl == player do
        {pos, pl, new_status}
      else
        data
      end
    end)
  end

  defp amount_bet_by(state, player) do
    Map.get(state.active_bets, player, 0)
  end

  defp phase_after(phase) do
    case phase do
      :preflop -> :flop
      :flop    -> :turn
      :turn    -> :river
      :river   -> :showdown
    end
  end
end
