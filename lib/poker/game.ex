defmodule Poker.Game do
  use GenServer

  alias Poker.{Player, Game}

  def start_link(players, {_sb, _bb} = blinds, id) when length(players) > 1 do
    GenServer.start_link(__MODULE__, [players, blinds, id], [name: via_tuple(id)])
  end

  def start_link(players, _blinds, _id) when length(players) <= 1 do
    {:error, :not_enough_players}
  end

  def init([players, {small_blind, big_blind}, id]) do
    {:ok, Game.State.new(small_blind: small_blind, 
                      big_blind: big_blind, 
                        players: players)}
  end

  def whereis(game_id) do
    :gproc.whereis_name({:n, :l, {:game, game_id}})
  end

  def players(game) do
    GenServer.call(game, :players)
  end

  def blinds(game) do
    GenServer.call(game, :blinds)
  end

  def next_action(game) do
    GenServer.call(game, :next_action)
  end

  def perform_action(game, %Game.Action{} = action) do
    GenServer.call(game, {:perform_action, action})
  end

  def handle_call(:players, _, %Game.State{ players: players } = state) do
    player_info = 
      players
      |> Enum.map(fn(p) -> Player.info(p) end)

    {:reply, player_info, state}
  end

  def handle_call(:blinds, _, %Game.State{ small_blind: small_blind, big_blind: big_blind } = state) do
    {:reply, {small_blind, big_blind}, state}
  end

  def handle_call({:perform_action, action}, _c, state) do
    case state |> Game.State.handle_action(action) do
      {:ok, new_state} -> {:reply, :ok, new_state}
    end
  end

  def handle_call(:next_action, _, state) do
    {:reply, state.next_action, state}
  end

  defp via_tuple(id) do
    {:via, :gproc, {:n, :l, {:game, id}}}
  end
end
