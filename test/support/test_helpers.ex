defmodule Poker.TestHelpers do

  alias Poker.{User, Repo}

  def add_json_api_headers(conn) do
    import Plug.Conn, only: [put_req_header: 3]

    conn
    |> put_req_header("accept", "application/vnd.api+json")
    |> put_req_header("content-type", "application/vnd.api+json")
  end

  def insert_user(attrs \\ %{}) do
    changes = Dict.merge(%{
      email: Faker.Internet.email,
      username: "user_#{Base.encode16(:crypto.rand_bytes(8))}", 
      password: "testing123"
    }, attrs)

    User.register_user_changeset(changes)
    |> Repo.insert!
  end

  def add_token_for(conn, user) do
    import Plug.Conn, only: [put_req_header: 3]

    {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :token)
    conn
    |> put_req_header("authorization", "Bearer " <> jwt)
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
