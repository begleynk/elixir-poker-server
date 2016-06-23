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
        |> render(Poker.UserView, :show, data: user)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Poker.RegistrationView, "error.json", changeset: changeset)
    end
  end
end
