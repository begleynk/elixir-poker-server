defmodule Poker.TokenView do
  use Poker.Web, :view
  use JaSerializer.PhoenixView

  attributes [:value]
end
