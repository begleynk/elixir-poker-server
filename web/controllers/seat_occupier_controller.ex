defmodule Poker.SeatOccupierController do
  use Poker.Web, :controller

  alias Poker.{Table, Player, SeatView}

  def edit(conn, %{"table_id" => table_id, "seat_id" => seat_id }, user) do
    Player.whereis(user.id)
    |> Player.join_table(table_id, seat: String.to_integer(seat_id))

    seat = 
      Table.whereis(table_id) 
      |> Table.info
      |> Map.fetch!(:seats) 
      |> Enum.find(&(&1.player == %Player{ id: user.id }))

    conn
    |> render(SeatView, :show, data: seat)
  end

  def action(conn, params) do
    apply(
      __MODULE__,
      action_name(conn),
      [
        conn, 
        conn.params, 
        Guardian.Plug.current_resource(conn),
      ]
    )
  end
end
