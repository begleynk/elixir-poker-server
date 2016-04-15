defmodule Poker.TableSupervisor do
  use Supervisor

  alias Poker.{Table}

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end
  
  def init(_) do
    children = [
      worker(Table, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_child(size: size) do
    Supervisor.start_child(__MODULE__, [[id: generate_id, size: size]])
  end

  def which_children do
    Supervisor.which_children(__MODULE__)
  end

  defp generate_id do
    "table_" <> (UUID.uuid4(:hex) |> String.slice(0, 8))
  end
end
