defmodule Poker.Router do
  use Poker.Web, :router

  pipeline :api do
    plug :accepts, ["json", "json-api"]
  end

  scope "/api", Poker do
    pipe_through :api

    scope "/v1" do
      post "/registrations", RegistrationController, :create
      resources "/session", TokenController, only: [:create]

      resources "/tables", TableController, only: [:index, :show, :create]
      resources "/current_user", CurrentUserController, only: [:show]
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", Poker do
  #   pipe_through :api
  # end
end
