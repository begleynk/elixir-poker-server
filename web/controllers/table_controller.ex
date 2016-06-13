defmodule Poker.TableController do
  use Poker.Web, :controller

  alias Poker.{Lobby, Table, TableView, TableIndexView}

  def index(conn, _params) do
    conn
    |> render(TableIndexView, :index, data: Lobby.tables)
  end

  def show(conn, %{ "id" => id }) do
    table_info =
      Table.whereis(id)
      |> Table.info

    conn
    |> render(TableView, :show, data: table_info)
  end
  
  def create(conn, %{ "data" => %{ "attributes" => %{ "size" => size, "blinds" => [sb, bb] }}}) do
    blinds = {String.to_integer(sb), String.to_integer(bb)}
    {:ok, table_info} = Lobby.create_table(size: String.to_integer(size), blinds: blinds)

    conn
    |> put_status(201)
    |> render(TableView, :show, data: table_info, include: "seats")
  end

  defp via_tuple(table_id) do
    {:via, :gproc, {:n, :l, {:table, table_id}}}
  end
end
