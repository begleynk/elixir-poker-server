defmodule Poker.Game.State do
  alias Poker.{Game, Deck}
  defstruct [
    id: nil, 
    players: [], 
    active_bets: Map.new,
    total_pot: 0,
    small_blind: nil, 
    big_blind: nil, 
    phase: :setup,
    next_action: nil,
    deck: Deck.new,
    pocket_cards: Map.new,
    event_store: Game.EventStore.new
  ]

  def new(id: id, small_blind: sb, big_blind: bb, players: [first_player | _rest] = players) do
    %Game.State{
      id: id,
      small_blind: sb,
      big_blind: bb,
      players: build_players(players),
      next_action: %Game.NextAction{
        player: first_player,
        type: :post_blind,
        to_call: sb,
        actions: [:call, :sit_out]
      }
    }
  end

  def handle_event(%Game.State{} = state, %Game.Event{} = event) do
    new_state 
      = state
      |> update_with_event(event)
      |> add_event_to_event_store(event)
      |> maybe_move_to_next_phase
      |> determine_next_action

    {:ok, new_state}
  end

  defp update_with_event(%Game.State{} = state, %Game.Event{} = event) do
    state
    |> calculate_bets(event)
    |> calculate_total_pot(event)
    |> set_player_status(event)
  end

  defp calculate_bets(%Game.State{active_bets: bets} = state, %Game.Event{type: type} = event) when type in [:call, :raise] do
    %Game.State{ state |
      active_bets: bets |> Map.update(event.player_id, event.amount, fn(_) -> event.amount end)
    }
  end

  defp calculate_bets(state, _event) do
    state
  end

  defp calculate_total_pot(%Game.State{total_pot: total_pot} = state, %Game.Event{amount: amount}) when is_integer(amount) do
    %Game.State{ state |
      total_pot: total_pot + amount
    }
  end

  defp calculate_total_pot(state, _event) do
    state
  end

  defp set_player_status(state, %Game.Event{type: :fold, player_id: player_id}) do
    %Game.State{ state |
      players: state.players |> Enum.map(fn({id, pos, status}) -> 
        if id == player_id do
          {id, pos, :folded}
        else
          {id, pos, status}
        end
      end)
    }
  end

  defp set_player_status(state, _event) do
    state
  end

  defp determine_next_action(state) do
    case state.phase do
      :setup -> next_setup_action(state)
           _ -> next_action(state)
    end
  end

  defp next_action(state) do
    next_action = 
      Game.NextAction.new
      |> determine_next_player(state)
      |> determine_next_action_type(state)
    
    %Game.State{ state | next_action: next_action }
  end

  # The only possible action will be handling the big blind
  defp next_setup_action(%Game.State{players: [_first, {id, _pos, _status} | _rest]} = state) do
    %Game.State{ state | 
      next_action: %Game.NextAction{
        player: id,
        type: :post_blind,
        to_call: state.big_blind,
        actions: [:call, :sit_out]
      }
    }
  end

  defp determine_next_player(action, %Game.State{phase: :preflop} = state) do
    if state |> only_blinds_have_been_paid? do
      player_after_big_blind = 
        state.players
        |> find_player_after(player_in_position(state.players, :big_blind))

      %Game.NextAction{ action | 
        player: player_after_big_blind
      }
    else
      %Game.NextAction{ action | 
        player: state.players |> find_player_after(state.next_action.player)
      }
    end
  end

  defp determine_next_player(action, %Game.State{next_action: previous_action} = state) do
    %Game.NextAction{ action | 
      player: state.players |> find_player_after(previous_action.player)
    }
  end

  defp determine_next_action_type(action, %Game.State{active_bets: bets}) do
    %Game.NextAction{ action |
      type: :answer_bet,
      to_call: highest_bet(bets) - (bets[action.player] || 0),
      actions: [:call, :fold, :raise]
    }
  end

  defp only_blinds_have_been_paid?(%Game.State{active_bets: bets, players: players, small_blind: sb, big_blind: bb}) do
    length(bets|> Map.to_list) == 2 
    && bets[player_in_position(players, :small_blind)] == sb
    && bets[player_in_position(players, :big_blind)] == bb
  end

  defp player_in_position(players, position) do
    players 
    |> Enum.find(fn({_,pos,_}) -> pos == position end)
    |> (fn({id, _, _}) -> id end).()
  end

  defp find_player_after([{target, _,_}, {match,_,_} | _rest], target) do
    match
  end

  defp find_player_after([a, b | rest], target) do
    find_player_after(Enum.concat([b], Enum.concat(rest,[a])), target)
  end

  defp maybe_move_to_next_phase(state) do
    if everyone_has_acted?(state) do
      move_to_next_phase(state)      
    else
      state
    end
  end

  def move_to_next_phase(%Game.State{phase: phase, players: players, deck: deck} = state) do
    case next_phase(phase) do
      :preflop -> 
        {new_deck, pocket_cards} = draw_pocket_cards(deck, players)
        %Game.State{ state | phase: :preflop, pocket_cards: pocket_cards, deck: new_deck }
    end
  end

  defp everyone_has_acted?(%Game.State{phase: :setup} = state) do
    blinds_have_been_paid?(state)
  end

  defp everyone_has_acted?(%Game.State{} = state) do
    all_active_players_have_paid_bets?(state)
  end

  defp all_active_players_have_paid_bets?(%Game.State{active_bets: bets} = state) do
    state.players
    |> active_players
    |> Enum.all?(fn(id) ->
      bets[id] == highest_bet(bets)
    end)
  end

  defp highest_bet(bets) do
    bets
    |> Map.to_list
    |> Stream.map(fn({_, amount}) -> amount end)
    |> Enum.max
  end

  defp active_players(players) do
    players
      |> Stream.filter(fn({_,_,status}) -> status == :playing end)
      |> Enum.map(fn({id, _,_}) -> id end)
  end

  defp blinds_have_been_paid?(%Game.State{players: [{sb,_,_}, {bb,_,_} | _players]} = state) do
    state.active_bets[sb] == state.small_blind && state.active_bets[bb] == state.big_blind
  end

  defp next_phase(phase) do
    case phase do
      :setup -> :preflop
    end
  end

  defp add_event_to_event_store(%Game.State{ event_store: store } = state, %Game.Event{} = event) do
    %Game.State{ state | 
      event_store: store |> Game.EventStore.add_event(event)
    }
  end

  defp draw_pocket_cards(deck, players) do
    Enum.reduce(players, {deck, Map.new}, fn({id, _,_}, {the_deck, hands}) ->
      {:ok, [card1, card2], new_deck} = Deck.draw_cards(the_deck, 2)
      {new_deck, Map.put(hands, id, {card1, card2})}
    end)
  end
  
  defp build_players(players) do
    build_players(players, [], 1)
  end

  defp build_players([], acc, _position) do
    Enum.reverse(acc)
  end

  defp build_players([player | []], acc, position) do
   build_players([], [{player, :button, :playing} | acc], position + 1)
  end

  defp build_players([player | rest], acc, position) do
     case position do
       1 -> build_players(rest, [{player, :small_blind, :playing} | acc], position + 1)
       2 -> build_players(rest, [{player, :big_blind, :playing} | acc], position + 1)
       _ -> build_players(rest, [{player, position, :playing} | acc], position + 1)
     end
  end
end
