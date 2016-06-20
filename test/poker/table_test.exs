defmodule Poker.TableTest do
  use ExUnit.Case

  alias Poker.{Player, Table}

  test "tables can be joined by players" do
    {:ok, player1} = Player.start_link("player_id_1")
    {:ok, player2} = Player.start_link("player_id_2")
    {:ok, table} = Table.start_link(id: "table_id", size: 6, blinds: {20,40})

    :ok = player1 |> Player.join_table("table_id", seat: 0)
    :ok = player2 |> Player.join_table("table_id", seat: 1)


    assert Table.seat(table, 0).player == "player_id_1"
    assert Table.seat(table, 1).player == "player_id_2"
  end

  test "a player cannot join a table twice" do
    {:ok, player1} = Player.start_link("player_id_1")
    {:ok, table} = Table.start_link(id: "table_id", size: 6, blinds: {20,40})

    :ok = player1 |> Player.join_table("table_id", seat: 1)
    assert {:error, :already_at_table} == player1 |> Player.join_table("table_id", seat: 2)

    state = Table.info(table)
    assert Table.seat(table, 1).player == "player_id_1"
  end

  test "a player cannot sit in an occupied seat" do
    {:ok, player1} = Player.start_link("player_id_1")
    {:ok, player2} = Player.start_link("player_id_2")
    {:ok, table} = Table.start_link(id: "table_id", size: 6, blinds: {20,40})

    :ok = player1 |> Player.join_table("table_id", seat: 1)
    assert {:error, :seat_taken} == player2 |> Player.join_table("table_id", seat: 1)

    assert Table.seat(table, 1).player == "player_id_1"
  end

  test "a player looses their seat if they disconnect" do
    {:ok, player1} = Player.start_link("player_id_1")
    {:ok, table} = Table.start_link(id: "table_id", size: 6, blinds: {20,40})

    :ok = player1 |> Player.join_table("table_id", seat: 1)
    assert Table.seat(table, 1).player == "player_id_1"

    Process.unlink(player1)
    Process.exit(player1, :kill)

    :timer.sleep 10 # Sleep just a tiny tiny bit

    assert Table.seat(table, 1).status == :empty
  end

  test "a player can leave a table" do
    {:ok, player1} = Player.start_link("player_id_1")
    {:ok, table} = Table.start_link(id: "table_id", size: 6, blinds: {20,40})

    :ok = player1 |> Player.join_table("table_id", seat: 1)

    assert Table.seat(table, 1).player == "player_id_1"

    :ok = player1 |> Player.leave_table("table_id")

    assert Table.seat(table, 1).status == :empty
  end

  test "a game starts when anough players join the table" do
    {:ok, _} = Table.start_link(id: "mah_table", size: 6, blinds: {20,40})

    {:ok, _} = Player.start_link("player_1")
    {:ok, _} = Player.start_link("player_2")

    assert (Table.whereis("mah_table") |> Table.current_game) == nil
    
    Player.whereis("player_1") |> Player.join_table("mah_table", seat: 1)

    assert (Table.whereis("mah_table") |> Table.current_game) == nil

    Player.whereis("player_2") |> Player.join_table("mah_table", seat: 2)

    :timer.sleep(10) # Need to sleep a teeny tiny bit

    assert (Table.whereis("mah_table") |> Table.current_game) != nil
  end
end
