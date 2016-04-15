defmodule Poker.TableEventTest do
  use ExUnit.Case

  alias Poker.{TableEvent, Table, Player}

  test 'can subscribe to new tables being created' do
    TableEvent.subscribe!

    {:ok, table} = Table.start_link(id: 'table_id', size: 6)

    %Table{id: id} = table_info = Table.info(table)

    assert_receive %TableEvent{
      type: :new_table,
      table: ^table_info,
      table_id: ^id,
      id: "table_event_" <> _rest
    }
  end

  test 'can subscribe players joining a table' do
    {:ok, player} = Player.start_link('player_id_1')
    {:ok, table} = Table.start_link(id: 'table_id', size: 6)

    TableEvent.subscribe!

    :ok = player |> Player.join_table('table_id', seat: 1)

    %Table{id: table_id} = table_info = Table.info(table)
    player_info = Player.info(player)

    assert_receive %TableEvent{
      type: :player_joined_table,
      info: %{
        player: ^player_info
      },
      table: ^table_info,
      table_id: ^table_id,
      id: "table_event_" <> _rest
    }
  end

  test 'can subscribe players leaving a table' do
    {:ok, player} = Player.start_link('player_id_1')
    {:ok, table} = Table.start_link(id: 'table_id', size: 6)

    :ok = player |> Player.join_table('table_id', seat: 1)

    TableEvent.subscribe!

    :ok = player |> Player.leave_table('table_id')

    %Table{id: table_id} = table_info = Table.info(table)
    player_info = Player.info(player)

    assert_receive %TableEvent{
      type: :player_left_table,
      info: %{
        player: ^player_info
      },
      table: ^table_info,
      table_id: ^table_id,
      id: "table_event_" <> _rest
    }
  end
end
