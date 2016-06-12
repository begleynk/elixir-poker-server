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
        |> render(:errors, errors: user_not_found_error)

      {:error, :invalid_password} ->
        conn
        |> put_status(422)
        |> render(:errors, errors: invalid_password_errors)
    end
  end

  def unauthenticated(conn, _) do
    conn
    |> put_status(403)
    |> render(Poker.TokenView, :errors, errors: invalid_or_missing_token)
  end

  defp invalid_or_missing_token do
    %{
      status: "403",
      code: "invalid token",
      title: "Authentication token missing from request"
    }
  end

  defp user_not_found_error do
    %{
      status: "422",
      code: "user not found",
      title: "User not found"
    }
  end

  defp invalid_password_errors do
    %{
      status: "422",
      code: "invalid password",
      title: "The provided password did not match the account",
      source: %{ pointer: "/data/attributes/password" }
    }
  end
end
