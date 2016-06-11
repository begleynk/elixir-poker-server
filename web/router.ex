defmodule Poker.Router do
  use Poker.Web, :router

  pipeline :api do
    plug :accepts, ["json", "json-api"]
  end

  scope "/api", Poker do
    pipe_through :api

    scope "/v1" do
      resources "/tables", TableController, only: [:index, :show, :create]
      resources "/session", SessionController, only: [:index]

      post "/registrations", RegistrationController, :create
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", Poker do
  #   pipe_through :api
  # end
end
