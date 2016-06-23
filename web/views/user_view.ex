defmodule Poker.UserView do
  use Poker.Web, :view
  use JaSerializer.PhoenixView

  location "/api/v1/users/:id"
  attributes [:email, :username]
end
