defmodule Poker.TestHelpers do

  def add_json_api_headers(conn) do
    import Plug.Conn, only: [put_req_header: 3]

    conn
    |> put_req_header("accept", "application/vnd.api+json")
    |> put_req_header("content-type", "application/vnd.api+json")
  end

  def clear_tables do
    sup = Process.whereis(Poker.TableSupervisor)
    sup
      |> Supervisor.which_children
      |> Enum.map(fn({_, pid, _, _}) ->
           Supervisor.terminate_child(sup, pid)
         end)
    :ok = Poker.Lobby.clear
  end
end
