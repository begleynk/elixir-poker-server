defmodule Poker.CurrentUserControllerTest do
  use Poker.ConnCase
  import Poker.TestHelpers

  setup %{conn: conn} = config do
    conn = 
      conn
      |> add_json_api_headers

    if username = config[:sign_in] do
      user = insert_user(username: username) 
      {:ok, conn: conn |> add_token_for(user), user: user}
    else
      {:ok, conn: conn}
    end
  end

  @tag sign_in: "TheDurr"
  test "GET /api/v1/users/me - retrieves the information of the current user", %{ conn: conn, user: user } do
    conn = get conn, current_user_path(conn, :index)

    assert response_content_type(conn, :json) =~ "charset=utf-8"
    assert %{
      "data" => %{
        "id" => id,
        "type" => "current-user",
        "attributes" => %{
          "email" => email,
          "username" => username
        },
        "links" => %{
          "self" => "/api/v1/current_user"
        }
      },
    } = json_response(conn, 200)

    assert id == user.id |> to_string
    assert username == user.username
    assert email == user.email
  end

  test "GET /api/v1/users/me - returns an error if not authenticated", %{ conn: conn } do
    conn = get conn, current_user_path(conn, :index)

    assert response_content_type(conn, :json) =~ "charset=utf-8"
    assert %{
      "errors" => [
        %{
          "title" => "invalid token",
          "detail" => "Authentication token missing from request"
        }
      ]
    } = json_response(conn, 403)
  end
end
