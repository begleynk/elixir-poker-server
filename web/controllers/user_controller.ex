defmodule Poker.UserController do
  use Poker.Web, :controller

  alias Poker.{Repo, User}

  plug :scrub_params, "data" when action in [:create]

  def create(conn, %{"data" => %{ "type" => "users", "attributes" => attrs }}) do
    changeset = User.register_user_changeset(attrs)

    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> render(:show, data: user)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("errors.json", errors: changeset)
    end
  end
end
