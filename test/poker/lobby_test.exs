defmodule Poker.LobbyTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = Poker.TableSupervisor.start_link

    on_exit fn ->
      Process.exit(pid, :kill)
    end

    :ok
  end

  test 'it starts with an empty list of tables' do
    {:ok, _lobby} = Poker.Lobby.start_link

    assert Poker.Lobby.tables == []
  end

  test 'it can start new tables' do
    {:ok, _lobby} = Poker.Lobby.start_link

    {:ok, _table_pid} = Poker.Lobby.create_table(size: 4)

    _tables = [table] = Poker.Lobby.tables

    assert table.size == 4
    assert table.seats == %{ 
      1 => :empty, 
      2 => :empty, 
      3 => :empty, 
      4 => :empty
    }
  end
end
