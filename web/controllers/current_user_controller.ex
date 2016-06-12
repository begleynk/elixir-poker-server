defmodule Poker.CurrentUserController do
  use Poker.Web, :controller

  def index(conn, _params, user) do
    conn
    |> put_status(200)
    |> render(Poker.CurrentUserView, :show, data: user)
  end

  def action(conn, _) do 
    apply(
      __MODULE__, 
      action_name(conn),
      [conn, conn.params, Guardian.Plug.current_resource(conn)]
    )
  end
end
