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
    {:ok, table_info, table_pid} = Lobby.create_table(size: 4, blinds: {20, 40})

    payload = %{
      "data" => %{
        "type" => "player",
        "id" => to_string(user_id)
      }
    }

    conn = patch conn, table_seat_occupier_path(conn, :edit, table_info.id, 0), payload
    
    table_info = Table.info(table_pid)
    assert %{
      player: ^user_id,
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

  @tag sign_in: "TheDurr"
  test "a player can leave a table", %{ conn: conn, user: %{ id: user_id }} do
    {:ok, player} = Player.start_link(user_id)
    {:ok, %Table{ id: table_id } = table_info, table_pid} = Lobby.create_table(size: 4, blinds: {20, 40})
    Player.join_table(player, table_info.id, seat: 0)

    payload = %{
      "data" => nil
    }

    conn = patch conn, table_seat_occupier_path(conn, :edit, table_info.id, 0), payload
    
    assert %{
      id: 0,
      position: 0,
      player: nil,
      status: :empty,
      table: ^table_id
    } = Table.seat(table_pid, 0)

    assert response_content_type(conn, :json) =~ "charset=utf-8"
    assert %{
      "data" => %{
        "id" => "0",
        "type" => "seat",
        "attributes" => %{
          "position" => "0",
          "status" => "empty"
        },
      }
    } = json_response(conn, 200)
  end
end
