defmodule Poker.Lobby do
  use GenServer

  alias Poker.{TableSupervisor, Table}

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
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

  def handle_call(:tables, _caller, s) do
    {:reply, do_fetch_tables_states, s}
  end

  def handle_call({:create_table, %{ size: size}}, _caller, s) do
    {:ok, table} = TableSupervisor.start_child(size: size)
    info = %Table{} = Table.info(table)

    {:reply, {:ok, info}, s}
  end

  defp do_fetch_tables_states do
    TableSupervisor.which_children
      |> Enum.map(fn({_, table, _, _}) -> Table.info(table) end)
  end
end
