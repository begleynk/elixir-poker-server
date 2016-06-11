defmodule Poker.RegistrationControllerTest do
  use Poker.ConnCase

  alias Poker.{TestHelpers, User, Repo}

  setup %{conn: conn} do
    {:ok, conn: conn |> TestHelpers.add_json_api_headers}
  end

  test "POST /api/v1/registrations - create a new user and get back a token", %{ conn: conn } do
    payload = %{
      "data" => %{
        "type" => "user",
        "attributes" => %{}
      }
    }

    conn = post conn, registration_path(conn, :create, payload)

    assert response_content_type(conn, :json) =~ "charset=utf-8"
    assert %{
      "data" => %{
        "type" => "token",
        "attributes" => %{
          "value" => jwt
        }
      }
    } = json_response(conn, 201)
    assert jwt != nil

    assert [
      %User{ username: username }
    ] = Repo.all(User)
    assert username != nil
  end
end
