defmodule Poker.TokenController do
  use Poker.Web, :controller

  def create(conn, %{ "data" => %{ "attributes" => attributes }}) do
    case Poker.Authentication.authenticate(attributes) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :token)

        conn
        |> put_status(201)
        |> render(:show, data: %{ value: jwt })

      {:error, :not_found} ->
        conn
        |> put_status(422)
        |> render("errors.json", errors: user_not_found_error)

      {:error, :invalid_password} ->
        conn
        |> put_status(422)
        |> render("errors.json", errors: invalid_password_errors)
    end
  end

  def unauthenticated(conn, _) do
    conn
    |> put_status(403)
    |> put_view(Poker.TokenView)
    |> render("errors.json", errors: invalid_or_missing_token)
  end

  defp invalid_or_missing_token do
    %{
      title: "invalid token",
      detail: "Authentication token missing from request"
    }
  end

  defp user_not_found_error do
    %{
      title: "user not found",
      detail: "User not found"
    }
  end

  defp invalid_password_errors do
    %{
      title: "invalid password",
      detail: "The provided password did not match the account",
      source: %{ pointer: "/data/attributes/password" }
    }
  end
end
