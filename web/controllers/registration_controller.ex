defmodule Poker.RegistrationController do
  use Poker.Web, :controller

  alias Poker.{Repo, User}

  plug :scrub_params, "data" when action in [:create]

  def create(conn, %{"data" => %{ "type" => "users" }}) do
    changeset = User.new_user_changeset

    case Repo.insert(changeset) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :token)

        conn
        |> put_status(:created)
        |> render(Poker.TokenView, :show, data: %{ value: jwt })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Poker.RegistrationView, "error.json", changeset: changeset)
    end
  end
end
