defmodule Poker.TableControllerTest do
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
  test "GET /api/v1/tables/:id", %{ conn: conn, user: _user } do
    {:ok, table, table_pid} = Poker.Lobby.create_table(size: 3, blinds: {20, 40})

    conn = get conn, table_path(conn, :show, table.id)

    assert response_content_type(conn, :json) =~ "charset=utf-8"
    assert %{
      "data" => %{
        "id" => id,
        "attributes" => %{
          "size" => 3,
          "blinds" => [20,40],
          "occupied-seats" => 0,
        },
        "relationships" => %{
          "seats" => %{
            "links" => %{
              "related" => table_seats_url
            },
            "data" => [
              %{ "type" => "seat", "id" => "0" },
              %{ "type" => "seat", "id" => "1" },
              %{ "type" => "seat", "id" => "2" }
            ]
          }
        },
        "links" => %{
          "self" => "/api/v1/tables/" <> id
        }
      },
      "included" => [
        %{
          "type" => "seat",
          "id" => "0",
          "attributes" => %{
            "status" => "empty",
          }
        },
        %{
          "type" => "seat",
          "id" => "1",
          "attributes" => %{
            "status" => "empty",
          }
        },
        %{
          "type" => "seat",
          "id" => "2",
          "attributes" => %{
            "status" => "empty",
          }
        }
      ]
    } = json_response(conn, 200)
    assert table_seats_url == "/api/v1/tables/" <> id <> "/seats"
  end

  @tag sign_in: "TheDurr"
  test "GET /api/v1/tables - returns list of running tables", %{ conn: conn, user: _user} do
    Poker.Lobby.create_table(size: 2, blinds: {20, 40})
    Poker.Lobby.create_table(size: 3, blinds: {20, 40})

    conn = get conn, table_path(conn, :index)

    assert response_content_type(conn, :json) =~ "charset=utf-8"
    assert %{
      "data" => [%{
        "id" => id,
        "attributes" => %{
          "size" => 2,
          "blinds" => [20,40],
          "occupied-seats" => 0
        },
        "links" => %{
          "self" => "/api/v1/tables/" <> id
        }
      }, %{
        "id" => id2,
        "attributes" => %{
          "size" => 3,
          "blinds" => [20,40],
          "occupied-seats" => 0
        },
        "links" => %{
          "self" => "/api/v1/tables/" <> id2
        }
      }]
    } = json_response(conn, 200)
  end

  @tag sign_in: "TheDurr"
  test "POST /api/v1/tables - creates a new table", %{ conn: conn, user: _user } do
    payload = %{
      "data" => %{
        "type" => "table",
        "attributes" => %{
          "size" => 4,
          "blinds" => [40,80]
        }
      }
    }
    conn = post conn, table_path(conn, :create, payload)

    assert response_content_type(conn, :json) =~ "charset=utf-8"
    assert %{
      "data" => %{
        "id" => id,
        "attributes" => %{
          "size" => 4,
          "blinds" => [40,80],
          "occupied-seats" => 0,
        },
        "relationships" => %{
          "seats" => %{
            "links" => %{
              "related" => table_seats_url
            },
            "data" => [
              %{ "type" => "seat", "id" => "0" },
              %{ "type" => "seat", "id" => "1" },
              %{ "type" => "seat", "id" => "2" },
              %{ "type" => "seat", "id" => "3" }
            ]
          }
        },
        "links" => %{
          "self" => "/api/v1/tables/" <> id
        }
      },
      "included" => [
        %{
          "type" => "seat",
          "id" => "0",
          "attributes" => %{
            "status" => "empty",
          }
        },
        %{
          "type" => "seat",
          "id" => "1",
          "attributes" => %{
            "status" => "empty",
          }
        },
        %{
          "type" => "seat",
          "id" => "2",
          "attributes" => %{
            "status" => "empty",
          }
        },
        %{
          "type" => "seat",
          "id" => "3",
          "attributes" => %{
            "status" => "empty",
          }
        }
      ]
    } = json_response(conn, 201)
    assert table_seats_url == "/api/v1/tables/" <> id <> "/seats"
  end
end
