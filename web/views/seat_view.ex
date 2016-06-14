defmodule Poker.SeatView do
  use Poker.Web, :view
  use JaSerializer.PhoenixView

  alias Poker.{Table, Player, TableView, PlayerView}

  location "/api/v1/tables/:table_id/seats/:id"
  attributes [:status, :position]

  has_one :player,
    serializer: PlayerView

  has_one :table,
    serializer: TableView

  def id(seat, _conn) do
    seat.id
  end

  def table_id(seat, _conn) do
    seat.table
  end

  def position(seat, _conn) do
    to_string(seat.position)
  end

  def player(seat, _conn) do
    case seat.player do
      nil -> nil 
      player -> 
        Player.whereis(player)
        |> Player.info
    end
  end

  def table(seat, _conn) do
    Table.whereis(seat.table)
    |> Table.info
  end
end
