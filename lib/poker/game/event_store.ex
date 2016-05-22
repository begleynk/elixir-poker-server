defmodule Poker.Game.EventStore do

  alias Poker.Game

  def new do
    []
  end

  def add_event(events, %Game.Event{} = action) do
    [action | events]
  end

  def last_action([action | _events]) do
    action
  end

  def from_beginning(events) do
    Enum.reverse(events)
  end
end
