defmodule Poker.Router do
  use Poker.Web, :router

  pipeline :api do
    plug :accepts, ["json", "json-api"]
    plug JaSerializer.ContentTypeNegotiation
    plug JaSerializer.Deserializer
  end

  scope "/api", Poker do
    pipe_through :api

    resources "/tables", TableController, only: [:index, :show]
    resources "/session", SessionController, only: [:index]
  end

  # Other scopes may use custom stacks.
  # scope "/api", Poker do
  #   pipe_through :api
  # end
end
