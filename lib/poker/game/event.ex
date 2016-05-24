defmodule Poker.Game.Event do
  defstruct [
    id: nil,
    type: nil,
    player: nil,
    phase: nil,
    amount: nil
  ]

  def new(%Poker.Game.Action{} = action) do
    %Poker.Game.Event{
      type: action.type,
      id: generate_id,
      player: action.player,
      amount: action.amount
    }
  end
  
  def phase_transition(new_phase) do
    %Poker.Game.Event{
      type: :phase_transition,
      phase: new_phase,
      id: generate_id
    }
  end

  defp generate_id do
    "table_event_" <> (UUID.uuid4(:hex) |> String.slice(0, 8))
  end
end
