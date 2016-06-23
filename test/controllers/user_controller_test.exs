defmodule Poker.UserControllerTest do
  use Poker.ConnCase

  alias Poker.{TestHelpers, User, Repo}

  setup %{conn: conn} do
    {:ok, conn: conn |> TestHelpers.add_json_api_headers}
  end

  test "POST /api/v1/users - creates a new user", %{ conn: conn } do
    payload = %{
      "data" => %{
        "type" => "users",
        "attributes" => %{
          "password" => "supersecret",
          "email"    => "foo@bar.com",
          "username" => "MahUsername"
        }
      }
    }

    conn = post conn, user_path(conn, :create, payload)

    assert response_content_type(conn, :json) =~ "charset=utf-8"
    assert %{
      "data" => %{
        "type" => "user",
        "id" => id,
        "attributes" => %{
          "email"    => "foo@bar.com",
          "username" => "MahUsername"
        }
      }
    } = json_response(conn, 201)
    assert id != nil

    assert [
      %User{ 
        username: "MahUsername",
        email: "foo@bar.com"
      }
    ] = Repo.all(User)
  end

  test "POST /api/v1/users - gives back error messages", %{ conn: conn } do
    payload = %{
      "data" => %{
        "type" => "users",
        "attributes" => %{
          "password" => "supersecret",
          "email"    => "notAnEmail",
          "username" => "MahUsername"
        }
      }
    }

    conn = post conn, user_path(conn, :create, payload)

    assert response_content_type(conn, :json) =~ "charset=utf-8"
    assert %{
      "errors" => [
        %{
          "source" => %{"pointer" => "/data/attributes/email"},
          "detail" => "Email has invalid format",
          "title"  => "has invalid format"
        }
      ]
    } = json_response(conn, 422)
  end
end
