defmodule Poker.TableTest do
  use ExUnit.Case

  alias Poker.{Player, Table}

  test 'tables can be joined by players' do
    {:ok, player1} = Player.start_link('player_id_1')
    {:ok, player2} = Player.start_link('player_id_2')
    {:ok, table} = Table.start_link('table_id', size: 6)

    :ok = player1 |> Player.join_table('table_id', seat: 1)
    :ok = player2 |> Player.join_table('table_id', seat: 2)

    state = Table.info(table)

    assert state.seats[1] == player1 |> Player.info
    assert state.seats[2] == player2 |> Player.info
  end

  test 'a player cannot join a table twice' do
    {:ok, player1} = Player.start_link('player_id_1')
    {:ok, table} = Table.start_link('table_id', size: 6)

    :ok = player1 |> Player.join_table('table_id', seat: 1)
    assert {:error, :already_at_table} == player1 |> Player.join_table('table_id', seat: 2)

    state = Table.info(table)
    assert state.seats[1] == player1 |> Player.info
  end

  test 'a player cannot sit in an occupied seat' do
    {:ok, player1} = Player.start_link('player_id_1')
    {:ok, player2} = Player.start_link('player_id_2')
    {:ok, table} = Table.start_link('table_id', size: 6)

    :ok = player1 |> Player.join_table('table_id', seat: 1)
    assert {:error, :seat_taken} == player2 |> Player.join_table('table_id', seat: 1)

    state = Table.info(table)
    assert state.seats[1] == player1 |> Player.info
  end

  test 'a player looses their seat if they disconnect' do
    {:ok, player1} = Player.start('player_id_1')
    {:ok, table} = Table.start_link('table_id', size: 6)

    :ok = player1 |> Player.join_table('table_id', seat: 1)
    state = Table.info(table)
    assert state.seats[1] == player1 |> Player.info

    player1 |> Process.exit(:kill)

    :timer.sleep 10 # Sleep just a tiny tiny bit

    state = Table.info(table)
    assert state.seats[1] == :empty
  end

  test 'a player can leave a table' do
    {:ok, player1} = Player.start('player_id_1')
    {:ok, table} = Table.start_link('table_id', size: 6)

    :ok = player1 |> Player.join_table('table_id', seat: 1)
    state = Table.info(table)
    assert state.seats[1] == player1 |> Player.info

    :ok = player1 |> Player.leave_table('table_id')

    state = Table.info(table)
    assert state.seats[1] == :empty
  end
end
