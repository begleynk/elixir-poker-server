defmodule Poker.GameSupervisor do
  use Supervisor

  alias Poker.{Game}

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end
  
  def init(_) do
    children = [
      worker(Game, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_child(players: players, blinds: blinds) do
    Supervisor.start_child(__MODULE__, [players, blinds, generate_id])
  end

  def which_children do
    Supervisor.which_children(__MODULE__)
  end

  defp generate_id do
    "game_" <> (UUID.uuid4(:hex) |> String.slice(0, 8))
  end
end
