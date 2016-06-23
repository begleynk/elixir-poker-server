defmodule Poker.TokenControllerTest do
  use Poker.ConnCase
  import Poker.TestHelpers

  setup %{conn: conn} do
    {:ok, conn: conn |> add_json_api_headers}
  end


  test "POST /api/v1/session - a user can get an authentication token if they have a valid username and password", %{ conn: conn } do
    password = Faker.Lorem.characters(%Range{first: 10, last: 10}) |> to_string

    user = insert_user(password: password) 

    payload = %{
      "data" => %{
        "type" => "user",
        "attributes" => %{
          "email" => user.email,
          "password" => password
        }
      }
    }

    conn = post conn, token_path(conn, :create, payload)

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
  end

  test "POST /api/v1/session - an error is returned if the user does not exist", %{ conn: conn } do
    payload = %{
      "data" => %{
        "type" => "user",
        "attributes" => %{
          "email" => "i@dont.exist",
          "password" => "dadadada"
        }
      }
    }

    conn = post conn, token_path(conn, :create, payload)

    assert response_content_type(conn, :json) =~ "charset=utf-8"
    assert %{
      "errors" => [
        %{
          "title"   => "user not found",
          "detail"  => "User not found"
        }
      ]
    } = json_response(conn, 422)
  end

  test "POST /api/v1/session - an error is returned if the password is incorrect", %{ conn: conn } do
    user = insert_user

    payload = %{
      "data" => %{
        "type" => "user",
        "attributes" => %{
          "email" => user.email,
          "password" => "totallythewrongpasswordyo"
        }
      }
    }

    conn = post conn, token_path(conn, :create, payload)

    assert response_content_type(conn, :json) =~ "charset=utf-8"
    assert %{
      "errors" => [
        %{
          "title"   => "invalid password",
          "detail"  => "The provided password did not match the account",
          "source"  => %{ "pointer" => "/data/attributes/password" }
        }
      ]
    } = json_response(conn, 422)
  end
end
