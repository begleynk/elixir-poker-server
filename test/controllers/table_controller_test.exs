defmodule Poker.TableControllerTest do
  use Poker.ConnCase

  alias Poker.{TestHelpers}

  setup %{conn: conn} do
    {:ok, conn: conn |> TestHelpers.add_json_api_headers}
  end

  test "GET /api/tables - returns list of running tables", %{ conn: conn } do
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
          "seats" => %{
            "1" => "empty",
            "2" => "empty"
          }
        },
        "links" => %{
          "self" => "/api/tables/" <> id
        }
      }, %{
        "id" => id2,
        "attributes" => %{
          "size" => 3,
          "blinds" => [20,40],
          "seats" => %{
            "1" => "empty",
            "2" => "empty",
            "3" => "empty"
          }
        },
        "links" => %{
          "self" => "/api/tables/" <> id2
        }
      }]
    } = json_response(conn, 200)
  end

  test "GET /api/tables/:id" do
    {:ok, table} = Poker.Lobby.create_table(size: 3, blinds: {20, 40})

    conn = get conn, table_path(conn, :show, table.id)

    assert response_content_type(conn, :json) =~ "charset=utf-8"
    assert %{
      "data" => %{
        "id" => id,
        "attributes" => %{
          "size" => 3,
          "blinds" => [20,40],
          "seats" => %{
            "1" => "empty",
            "2" => "empty",
            "3" => "empty"
          }
        },
        "links" => %{
          "self" => "/api/tables/" <> id
        }
      }
    } = json_response(conn, 200)
  end

  test "POST /api/tables - creates a new table" do
    payload = %{
      "data" => %{
        "type" => "table",
        "attributes" => %{
          "size" => 4,
          "blinds" => [20,40]
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
          "seats" => %{
            "1" => "empty",
            "2" => "empty",
            "3" => "empty",
            "4" => "empty"
          }
        },
        "links" => %{
          "self" => "/api/tables/" <> id
        }
      }
    } = json_response(conn, 201)
  end
end
