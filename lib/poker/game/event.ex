defmodule Poker.Game.Event do
  alias Poker.Game
  defstruct [
    id: nil,
    game_id: nil,
    type: nil,
    player: nil,
    info: %{}
  ]

  @types [:call, :bet, :raise, :check, :fold, :phase_transition]

  def from_action(%Game.Action{type: type} = action) when type in [:call, :bet, :raise] do
    %Game.Event{
      type: type,
      id: generate_id,
      player: action.player,
      info: %{
        amount: action.amount
      }
    }
  end
  
  def from_action(%Game.Action{} = action) do
    %Game.Event{
      type: action.type,
      id: generate_id,
      player: action.player
    }
  end
  
  def phase_transition(new_phase) do
    %Game.Event{
      type: :phase_transition,
      info: %{ phase: new_phase },
      id: generate_id
    }
  end

  def subscribe!(table_id) do
    :gproc.reg(address(table_id))
  end

  def unsubscribe(table_id) do
    :gproc.unreg(address(table_id))
  end

  def broadcast!(%Game.Event{ type: type } = event) when type in @types do
    :gproc.send(address(event.table_id), event)
  end

  defp address(table_id) do
    {:p, :l, {:poker_topic, :game_events, table_id}}
  end

  defp generate_id do
    "table_event_" <> (UUID.uuid4(:hex) |> String.slice(0, 8))
  end
end
