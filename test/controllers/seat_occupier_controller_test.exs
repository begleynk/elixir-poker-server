defmodule Poker.SeatOccupierControllerTest do
  use Poker.ConnCase
  import Poker.TestHelpers

  alias Poker.{Lobby, Table, Player}

  setup %{conn: conn} = config do
    conn = add_json_api_headers(conn)

    if username = config[:sign_in] do
      user = insert_user(username: username)
      {:ok, conn: conn |> add_token_for(user), user: user}
    else
      {:ok, conn: conn}
    end
  end

  @tag sign_in: "TheDurr"
  test "a player can sit down at a table", %{ conn: conn, user: %{ id: user_id }} do
    {:ok, table_info} = Lobby.create_table(size: 4, blinds: {20, 40})

    payload = %{
      "data" => %{
        "type" => "player",
        "id" => to_string(user_id)
      }
    }

    conn = patch conn, table_seat_occupier_path(conn, :edit, table_info.id, 0), payload
    
    table_info = Table.whereis(table_info.id) |> Table.info
    assert %{
      player: %Player{ id: ^user_id },
      status: :playing
    } = table_info.seats |> Enum.at(0)

    assert response_content_type(conn, :json) =~ "charset=utf-8"
    assert %{
      "data" => %{
        "id" => "0",
        "type" => "seat",
        "attributes" => %{
          "position" => "0",
          "status" => "playing"
        },
      }
    } = json_response(conn, 200)
  end
end
