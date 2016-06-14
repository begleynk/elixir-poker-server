defmodule Poker.LobbyTest do
  use Poker.PokerCase

  alias Poker.{Lobby, Player, Table}

  test "it starts with an empty list of tables" do
    assert Lobby.tables == []
  end

  test "it can start new tables" do
    {:ok, table, _table_pid} = Lobby.create_table(size: 4, blinds: {20, 40})

    _tables = [table] = Lobby.tables

    assert table.id != nil
    assert table.size == 4
    assert length(table.seats) == 4
  end

  test "it tracks table events to update its local caches of tables" do
    {:ok, player} = Player.start_link("player_id_1")
    {:ok, table, table_pid} = Lobby.create_table(size: 4, blinds: {20, 40})
    
    assert [table] = Lobby.tables

    Player.join_table(player, table.id, seat: 1)

    assert Table.seat(table_pid, 1).player == "player_id_1"

    Player.leave_table(player, table.id)

    assert Table.seat(table_pid, 1).status == :empty
  end
end
