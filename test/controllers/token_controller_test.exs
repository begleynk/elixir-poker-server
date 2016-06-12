defmodule Poker.TokenControllerTest do
  use Poker.ConnCase

  alias Poker.{TestHelpers, User, Repo}

  setup %{conn: conn} do
    {:ok, conn: conn |> TestHelpers.add_json_api_headers}
  end


  test "POST /api/v1/session - a user can get an authentication token if they have a valid username and password", %{ conn: conn } do
    email = Faker.Internet.email
    password = Faker.Lorem.characters(%Range{first: 10, last: 10}) |> to_string

    User.new_user_changeset
    |> Repo.insert!
    |> User.register_user_changeset(%{email: email, password: password})
    |> Repo.update

    payload = %{
      "data" => %{
        "type" => "user",
        "attributes" => %{
          "email" => email,
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
          "status" => "422",
          "code"   => "user not found",
          "title"  => "User not found"
        }
      ]
    } = json_response(conn, 422)
  end

  test "POST /api/v1/session - an error is returned if the password is incorrect", %{ conn: conn } do
    email = Faker.Internet.email
    password = Faker.Lorem.characters(%Range{first: 10, last: 10}) |> to_string

    User.new_user_changeset
    |> Repo.insert!
    |> User.register_user_changeset(%{email: email, password: password})
    |> Repo.update

    payload = %{
      "data" => %{
        "type" => "user",
        "attributes" => %{
          "email" => email,
          "password" => "totallythewrongpasswordyo"
        }
      }
    }

    conn = post conn, token_path(conn, :create, payload)

    assert response_content_type(conn, :json) =~ "charset=utf-8"
    assert %{
      "errors" => [
        %{
          "status" => "422",
          "code"   => "invalid password",
          "source" => %{ "pointer" => "/data/attributes/password" },
          "title"  => "The provided password did not match the account"
        }
      ]
    } = json_response(conn, 422)
  end
end
