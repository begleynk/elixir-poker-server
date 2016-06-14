defmodule Poker.CurrentUserController do
  use Poker.AuthenticatedController

  def index(conn, _params, user) do
    conn
    |> put_status(200)
    |> render(Poker.CurrentUserView, :show, data: user)
  end
end
