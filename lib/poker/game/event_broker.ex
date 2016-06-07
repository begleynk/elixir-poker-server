defmodule Poker.Game.EventBroker do
  alias Poker.Game

  @event_types [:call, :bet, :raise, :check, :fold, :phase_transition]

  def unsubscribe(table_id) do
    table_id
    |> table_address
    |> :gproc.unreg
  end

  def subscribe!(table_id) do
    table_id
    |> table_address
    |> :gproc.reg
  end

  def broadcast!(%Game.Event{ type: type } = event) when type in @event_types do
    event
    |> add_identifier
    |> do_broadcast
  end

  defp add_identifier(event) do
    %Game.Event{ event | id: generate_id }
  end

  defp do_broadcast(%Game.Event{ table_id: table_id } = event) do
    table_id
    |> table_address
    |> :gproc.send(event)
  end

  defp table_address(table_id) do
    {:p, :l, {:poker_topic, :game_events, table_id}}
  end

  defp generate_id do
    "table_event_" <> (UUID.uuid4(:hex) |> String.slice(0, 8))
  end
end
