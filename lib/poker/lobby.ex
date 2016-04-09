defmodule Poker.Lobby do
  use GenServer

  alias Poker.{TableSupervisor, Table}

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, []}
  end

  def tables do
    GenServer.call(__MODULE__, :tables)
  end

  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  def create_table(size: size) do
    GenServer.call(__MODULE__, {:create_table, %{ size: size }})
  end

  def handle_call(:tables, _caller, state) do
    {:reply, state, state}
  end

  def handle_call(:clear, _caller, state) do
    {:reply, :ok, []}
  end

  def handle_call({:create_table, %{ size: size}}, _caller, state) do
    {:ok, table} = TableSupervisor.start_child(size: size)
    info = %Table{} = Table.info(table)

    {:reply, {:ok, info}, state ++ [info]}
  end
end
