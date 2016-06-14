defmodule Poker.Router do
  use Poker.Web, :router

  pipeline :api do
    plug :accepts, ["json", "json-api"]
  end

  pipeline :authenticated_api do
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.EnsureAuthenticated, handler: Poker.TokenController
    plug Guardian.Plug.LoadResource
  end

  scope "/api", Poker do
    pipe_through :api

    scope "/v1" do
      post "/registrations", RegistrationController, :create
      post "/tokens", TokenController, :create

      # All routes below are authenticated
      pipe_through :authenticated_api

      get "/current_user", CurrentUserController, :index
      resources "/tables", TableController, only: [:index, :show, :create] do
        resources "/seats", SeatController, only: [] do
          patch "/occupier", SeatOccupierController, :edit, as: "occupier"
        end
      end
    end
  end
end
