defmodule Poker.Table.Event do
  defstruct [
    id: nil, 
    table_id: nil, 
    type: nil, 
    table: nil, 
    info: %{}
  ]

  alias Poker.{Table}

  @address {:p, :l, {:poker_topic, :table_events}}
  @types [:new_table, :player_joined_table, :player_left_table]

  def subscribe! do
    :gproc.reg(@address)
  end

  def broadcast!(%Table.Event{ type: type } = event) when type in @types do
    do_broadcast(%Table.Event{ event | 
      id: generate_id
    })
  end

  defp do_broadcast(event) do
    :gproc.send(@address, event)
  end

  defp generate_id do
    "table_event_" <> (UUID.uuid4(:hex) |> String.slice(0, 8))
  end
end
