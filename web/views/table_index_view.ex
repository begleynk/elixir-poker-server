defmodule Poker.TableIndexView do
  use Poker.Web, :view
  use JaSerializer.PhoenixView

  alias Poker.{Table}

  location "/api/v1/tables/:id"
  attributes [:size, :blinds, :occupied_seats]

  def blinds(%Table{ blinds: {sb, bb}}, _conn) do
    [sb, bb]
  end

  def occupied_seats(table, _conn) do
    Enum.count(table.seats, (&(&1.status !== :empty)))
  end
end
