defmodule Poker.Game do
  use GenServer

  alias Poker.{Player, Game}

  # Initialization

  def start_link(players, {_sb, _bb} = blinds, id) when length(players) > 1 do
    GenServer.start_link(__MODULE__, [players, blinds, id], [name: via_tuple(id)])
  end

  def start_link(players, _blinds, _id) when length(players) <= 1 do
    {:error, :not_enough_players}
  end

  def init([players, {small_blind, big_blind}, id]) do
    {
      :ok, 
      Game.State.new(id: id, small_blind: small_blind, big_blind: big_blind, players: players),
    }
  end

  # Public API

  def whereis(game_id) do
    :gproc.whereis_name({:n, :l, {:game, game_id}})
  end

  def state(game) do
    GenServer.call(game, :state)
  end

  def perform_action(game, %Game.Event{} = action) do
    GenServer.call(game, {:perform_action, action})
  end

  def players(game) do
    state(game).players
    |> Enum.map(fn({p, _pos, _status}) -> p |> Player.whereis |> Player.info end)
  end

  def blinds(game) do
    %Game.State{big_blind: big_blind, small_blind: small_blind} = state(game)
    {small_blind, big_blind}
  end

  def next_action(game) do
    state(game).next_action
  end

  def phase(game) do
    state(game).phase
  end

  # OTP Callbacks

  def handle_call({:perform_action, action}, _c, state) do
    case state |> Game.State.handle_event(action) do
      {:ok, new_state} -> {:reply, :ok, new_state}
    end
  end

  def handle_call(:state, _, state) do
    {:reply, state, state}
  end

  defp via_tuple(id) do
    {:via, :gproc, {:n, :l, {:game, id}}}
  end
end
