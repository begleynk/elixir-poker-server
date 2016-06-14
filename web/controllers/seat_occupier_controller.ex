defmodule Poker.SeatOccupierController do
  use Poker.AuthenticatedController

  alias Poker.{Table, Player, SeatView}

  def edit(conn, %{"table_id" => table_id, "seat_id" => seat_id }, user) do
    Player.whereis(user.id)
    |> Player.join_table(table_id, seat: String.to_integer(seat_id))

    seat = 
      Table.whereis(table_id) 
      |> Table.seat(String.to_integer(seat_id))

    conn
    |> render(SeatView, :show, data: seat)
  end
end
