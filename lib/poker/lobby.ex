defmodule Poker.Lobby do
  use GenServer

  alias Poker.{TableSupervisor, Table}

  @tracked_table_events [
    :player_joined_table,
    :player_left_table
  ]

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Table.Event.subscribe!

    {:ok, fetch_initial_tables_states}
  end

  # Public API

  def tables do
    GenServer.call(__MODULE__, :tables)
  end

  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  def create_table(size: size) do
    GenServer.call(__MODULE__, {:create_table, %{ size: size }})
  end

  # GenServer Callbacks

  def handle_call(:tables, _caller, s) do
    {:reply, s, s}
  end

  def handle_call({:create_table, %{ size: size }}, _caller, s) do
    {:ok, table} = TableSupervisor.start_child(size: size)
    info = %Table{} = Table.info(table)

    {:reply, {:ok, info}, s}
  end

  def handle_call(:clear, _,_table) do
    {:reply, :ok, []}
  end

  def handle_info(%Table.Event{type: :new_table, table: table}, tables) do
    {:noreply, tables ++ [table]}
  end

  def handle_info(%Table.Event{type: type} = event, tables) when type in @tracked_table_events do
    {:noreply, tables |> update_with_event(event)}
  end

  def handle_info(_message, tables) do
    {:noreply, tables}
  end

  # Private Methods

  defp fetch_initial_tables_states do
    TableSupervisor.which_children
      |> Enum.map(fn({_, table, _, _}) -> Table.info(table) end)
  end

  defp update_with_event(tables, %Table.Event{table: updated_table, table_id: table_id}) do
    tables |> Enum.map(fn(%Table{} = table) ->
      if table.id == table_id do
        updated_table
      else
        table
      end
    end)
  end
end
