defmodule Poker.LobbyTest do
  use Poker.PokerCase

  alias Poker.{Lobby, Player}

  test 'it starts with an empty list of tables' do
    assert Lobby.tables == []
  end

  test 'it can start new tables' do
    {:ok, _table_pid} = Lobby.create_table(size: 4)

    _tables = [table] = Lobby.tables

    assert table.id != nil
    assert table.size == 4
    assert table.seats == %{ 
      1 => :empty, 
      2 => :empty, 
      3 => :empty, 
      4 => :empty
    }
  end

  test 'it tracks table events to update its local caches of tables' do
    {:ok, player} = Player.start_link('player_id_1')
    {:ok, _table_pid} = Lobby.create_table(size: 4)
    
    [table] = Lobby.tables

    Player.join_table(player, table.id, seat: 1)

    [updated_table] = Lobby.tables 
    assert updated_table.seats[1] == Player.info(player)

    Player.leave_table(player, updated_table.id)

    [updated_table] = Lobby.tables 
    assert updated_table.seats[1] == :empty
  end
end
