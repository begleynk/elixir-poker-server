defmodule Poker.TableController do
  use Poker.Web, :controller

  alias Poker.{Lobby, Table}

  def index(conn, _params) do
    render conn, data: Lobby.tables
  end

  def show(conn, %{ "id" => id }) do
    render conn, data: Table.info(via_tuple(id))
  end

  defp via_tuple(table_id) do
    {:via, :gproc, {:n, :l, {:table, table_id}}}
  end
end
