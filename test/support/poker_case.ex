defmodule Poker.PokerCase do
  use ExUnit.CaseTemplate

  setup do
    Poker.TestHelpers.clear_tables 
    :ok
  end
end
