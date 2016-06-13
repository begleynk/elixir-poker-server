defmodule Poker.SeatControllerTest do
  use Poker.ConnCase
  import Poker.TestHelpers

  setup %{conn: conn} = config do
    conn = add_json_api_headers(conn)

    if username = config[:sign_in] do
      user = insert_user(username: username) 
      {:ok, conn: conn |> add_token_for(user), user: user}
    else
      {:ok, conn: conn}
    end
  end
end
