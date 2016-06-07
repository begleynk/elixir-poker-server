defmodule Poker.Game.Event do
  alias Poker.Game
  defstruct [
    id: nil,
    game_id: nil,
    table_id: nil,
    type: nil,
    player: nil,
    info: %{}
  ]


  def from_action(%Game.Action{type: type} = action) when type in [:call, :bet, :raise] do
    %Game.Event{
      type: type,
      player: action.player,
      info: %{
        amount: action.amount
      }
    }
  end
  
  def from_action(%Game.Action{} = action) do
    %Game.Event{
      type: action.type,
      player: action.player
    }
  end
  
  def phase_transition(new_phase) do
    %Game.Event{
      type: :phase_transition,
      info: %{ phase: new_phase },
    }
  end
end
