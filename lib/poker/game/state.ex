defmodule Poker.Game.State do
  alias Poker.Game
  defstruct [
    id: nil, 
    players: [], 
    small_blind: nil, 
    big_blind: nil, 
    phase: :setup,
    events: Game.EventStore.new,
    next_action: nil
  ]

  def new(small_blind: sb, big_blind: bb, players: players) do
    %Game.State{
      small_blind: sb,
      big_blind: bb,
      players: players,
    } |> determine_next_action
  end

  def handle_action(%Game.State{events: events} = state, %Game.Action{} = action) do
    state
    |> add_event(action)
    |> determine_next_state
  end

  defp build_first_action([first | _rest], small_blind) do
  end

  defp add_event(%Game.State{events: events} = state, action) do
    %Game.State{ state |
      events: events |> Game.EventStore.add_event(action)
    }
  end

  # When no events have happened, setup first action (call small blind)
  defp determine_next_action(%Game.State{events: []} = state) do
    %Game.State{ 
      next_action: %Game.NextAction{
        player: first,
        type: :post_blind,
        to_call: small_blind,
        actions: [:call, :sit_out]
      }
    }
  end

  defp determine_next_action(%Game.State{events: events} = state) do
    determine_next_action(state, Game.EventStore.from_beginning(events), [], Map.new)
  end

  defp determine_next_action(%Game.State{} = state, [next_event | rest], processed, meta) do
    raise "Figure out how we are going to calculate the state every time here"
  end
end
