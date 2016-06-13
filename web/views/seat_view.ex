defmodule Poker.SeatView do
  use Poker.Web, :view
  use JaSerializer.PhoenixView

  location "/api/v1/tables/:table_id/seats/:id"
  attributes [:status]

  def id(seat, _conn) do
    seat.id
  end

  def table_id(seat, _conn) do
    seat.table
  end
end
