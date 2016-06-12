defmodule Poker.CurrentUserView do
  use Poker.Web, :view
  use JaSerializer.PhoenixView

  location "/api/v1/current_user"
  attributes [:email, :username]
end
