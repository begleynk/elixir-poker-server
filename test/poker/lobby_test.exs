defmodule Poker.LobbyTest do
  use Poker.PokerCase

  test 'it starts with an empty list of tables' do
    assert Poker.Lobby.tables == []
  end

  test 'it can start new tables' do
    {:ok, _table_pid} = Poker.Lobby.create_table(size: 4)

    _tables = [table] = Poker.Lobby.tables

    assert table.id != nil
    assert table.size == 4
    assert table.seats == %{ 
      1 => :empty, 
      2 => :empty, 
      3 => :empty, 
      4 => :empty
    }
  end
end
