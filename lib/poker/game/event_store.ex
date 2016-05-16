defmodule Poker.Game.EventStore do

  alias Poker.Game

  def new do
    []
  end

  def add_event(events, %Game.Action{} = action) do
    [action | events]
  end

  def from_beginning(events) do
    Enum.reverse(events)
  end
end
