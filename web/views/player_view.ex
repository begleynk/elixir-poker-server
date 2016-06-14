defmodule Poker.PlayerView do
  use Poker.Web, :view
  use JaSerializer.PhoenixView

  location "/api/v1/players"
end
