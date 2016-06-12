defmodule Poker.TokenController do
  use Poker.Web, :controller

  def create(conn, %{ "data" => %{ "attributes" => attributes }}) do
    case Poker.Authentication.authenticate(attributes) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :token)

        conn
        |> put_status(:created)
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
