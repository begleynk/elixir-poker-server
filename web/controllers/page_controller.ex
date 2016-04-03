defmodule Poker.PageController do
  use Poker.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
