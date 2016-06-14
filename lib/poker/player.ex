defmodule Poker.Player do
  defstruct id: nil

  alias Poker.{Player, Table, Game, Game.Event}
  use GenServer

  def start_link(id) do
    GenServer.start_link(__MODULE__, [id], [name: via_tuple(id)])
  end

  def start(id) do
    GenServer.start(__MODULE__, [id], [])
  end

  def init([id]) do
    {:ok, %Player{id: id}}
  end

  def whereis(player_id) do
    case :gproc.whereis_name({:n, :l, {:player, player_id}}) do
      :undefined -> 
        {:ok, player_pid} = Player.start_link(player_id)
        player_pid
      pid -> 
        pid
    end
  end

  def info(player) do
    GenServer.call(player, :info)
  end

  def join_table(player, table_id, seat: seat) do
    GenServer.call(player, {:join_table, table_id, seat})
  end

  def leave_table(player, table_id) do
    GenServer.call(player, {:leave_table, table_id})
  end

  def perform_action(player, game_id, %Game.Event{} = action) do
    GenServer.call(player, {:perform_action, game_id, action})
  end

  def handle_call(:info, _, %Player{} = state) do
    {:reply, state, state}
  end

  def handle_call({:join_table, table_id, seat}, _c, %Player{} = state) do
    case Table.whereis(table_id) |> Table.sit(player: state, seat: seat) do
      :ok -> {:reply, :ok, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:leave_table, table_id}, _c, %Player{} = state) do
    case Table.whereis(table_id) |> Table.leave do
      :ok -> {:reply, :ok, state}
    end
  end

  def handle_call({:perform_action, game_id, action}, _c, %Player{} = state) do
    action = action |> Game.Event.specify_player(state.id)

    case Game.whereis(game_id) |> Game.perform_action(action) do
      :ok -> {:reply, :ok, state}
    end
  end

  defp via_tuple(id) do
    {:via, :gproc, {:n, :l, {:player, id}}}
  end
end
