defmodule Poker.Game.EventParser do

  alias Poker.Game

  def everyone_has_acted_in_phase?(%Game.State{} = state, phase) do
    result = players_acted_in_phase(state, phase)

    case phase do
      :setup -> 
        result.players
        |> Map.to_list
        |> (fn([{_, sb}, {_, bb} | _rest]) -> sb.bet == state.small_blind && bb.bet == state.big_blind  end).()
      _ -> 
        all_remaning_players_called_bets?(result.players)
    end
  end

  defp players_acted_in_phase(%Game.State{} = state, phase) do
    players_acted_in_phase(state.event_store |> Game.EventStore.from_beginning, 
                           phase, state, %{players: build_player_state_holder(state.positions), phase: :setup})
  end

  defp players_acted_in_phase([], _phase, _state, result) do
    result
  end

  defp players_acted_in_phase([%Game.Event{type: :phase_transition}], _phase, _state, result) do
    result
  end

  defp players_acted_in_phase([%Game.Event{type: :phase_transition, phase: :preflop} | rest], phase, state, result) do
    players_acted_in_phase(rest, phase, state,
      %{ result | 
        phase: :preflop,
        players: result.players # Mark everyone as not acted, but keep old bets
         |> Map.to_list
         |> Enum.map(fn({id, data}) -> {id, Map.put(data, :acted, false)} end)
         |> Enum.into(Map.new)
      }
    )
  end

  defp players_acted_in_phase([%Game.Event{type: :phase_transition} = event | rest], phase, state, result) do
    players_acted_in_phase(rest, phase, state,
      %{ result | players: build_player_state_holder(state.positions), phase: event.phase}
    )
  end

  defp players_acted_in_phase([event | rest], phase, state, result) do
    players_acted_in_phase(rest, phase, state, %{result | players: result.players |> update_player_state(event)})
  end

  defp update_player_state(players, event) do
    case event.type do
      :fold -> 
        players
        |> put_in([event.player, :acted], true)
        |> put_in([event.player, :status], :folded)
      :check -> 
        players
        |> put_in([event.player, :acted], true)
      :raise -> 
        players
        |> put_in([event.player, :acted], true)
        |> put_in([event.player, :bet], event.amount)
      _ -> 
        players
        |> put_in([event.player, :acted], true)
        |> put_in([event.player, :bet], (players |> Map.get(event.player) |> Map.get(:bet)) + event.amount)
    end
  end

  defp all_remaning_players_called_bets?(players) do
    highest_bet = 
      players
      |> Map.to_list
      |> Enum.map(fn({_, state}) -> state.bet end)
      |> Enum.max

    players
    |> Map.to_list
    |> Enum.filter(fn({_, state}) -> state.status == :playing end)
    |> Enum.all?(fn({_, state}) -> state.bet == highest_bet && state.acted end)
  end

  defp build_player_state_holder(player_positions) do
    player_positions
    |> Stream.map(fn({_pos, player, _s}) -> {player, %{acted: false, bet: 0, status: :playing}} end)
    |> Enum.into(Map.new)
  end
end
