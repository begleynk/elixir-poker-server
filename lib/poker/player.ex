defmodule Poker.Player do
  defstruct id: nil

  alias Poker.{Player, Table}
  use GenServer

  def start_link(id) do
    GenServer.start_link(__MODULE__, [id], [])
  end

  def start(id) do
    GenServer.start(__MODULE__, [id], [])
  end

  def init([id]) do
    {:ok, %Player{id: id}}
  end

  def info(player) do
    GenServer.call(player, :info)
  end

  def join_table(player, table_id, seat: seat) do
    GenServer.call(player, {:join_table, table_id, seat})
  end

  def handle_call(:info, _, %Player{} = state) do
    {:reply, state, state}
  end

  def handle_call({:join_table, table_id, seat}, _c, %Player{} = state) do
    case Table.sit(via_tuple(table_id), player: state, seat: seat) do
      :ok -> {:reply, :ok, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  defp via_tuple(table_id) do
    {:via, :gproc, {:n, :l, {:table, table_id}}}
  end
end