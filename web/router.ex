defmodule Poker.Router do
  use Poker.Web, :router

  pipeline :api do
    plug :accepts, ["json", "json-api"]
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
  end

  pipeline :authenticated_api do
    plug Guardian.Plug.EnsureAuthenticated, handler: Poker.TokenController
  end

  scope "/api", Poker do
    pipe_through :api

    scope "/v1" do
      post "/users", UserController, :create
      post "/tokens", TokenController, :create
      resources "/tables", TableController, only: [:index, :show]

      # All routes below are authenticated
      pipe_through :authenticated_api

      get "/users/me", CurrentUserController, :index

      resources "/tables", TableController, only: [:create] do
        resources "/seats", SeatController, only: [] do
          patch "/occupier", SeatOccupierController, :edit, as: "occupier"
        end
      end
    end
  end
end
