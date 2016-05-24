defmodule Poker.Game.EventParserTest do
  use ExUnit.Case

  alias Poker.Game.{State, Action, EventParser}

  test "it tells you if blinds have not been paid yet" do
    state = 
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3", "p4"])
      |> State.handle_action(Action.call("p1", amount: 10))

    assert EventParser.everyone_has_acted_in_phase?(state, :setup) == false
  end

  test "it tells you if all blinds have been paid" do
    state = 
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3", "p4"])
      |> State.handle_action(Action.call("p1", amount: 10))
      |> State.handle_action(Action.call("p2", amount: 20))

    assert EventParser.everyone_has_acted_in_phase?(state, :setup) == true
  end

  test "it tells you if everyone has acted preflop" do
    state = 
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3", "p4"])
      |> State.handle_action(Action.call("p1", amount: 10))
      |> State.handle_action(Action.call("p2", amount: 20))
      |> State.handle_action(Action.call("p3", amount: 20))
      |> State.handle_action(Action.call("p4", amount: 20))
      |> State.handle_action(Action.call("p1", amount: 10))

    assert EventParser.everyone_has_acted_in_phase?(state, :preflop) == false
  end

  test "only says everyone has acted preflop when the big blind has also acted" do
    state = 
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3", "p4"])
      |> State.handle_action(Action.call("p1", amount: 10))
      |> State.handle_action(Action.call("p2", amount: 20))
      |> State.handle_action(Action.call("p3", amount: 20))
      |> State.handle_action(Action.call("p4", amount: 20))
      |> State.handle_action(Action.call("p1", amount: 10))
      |> State.handle_action(Action.check("p2")) # BB Checks

    assert EventParser.everyone_has_acted_in_phase?(state, :preflop) == true
  end

  test "everyone has acted only once they have matched the bets of that round" do
    state = 
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3", "p4"])
      |> State.handle_action(Action.call("p1", amount: 10))
      |> State.handle_action(Action.call("p2", amount: 20))
      |> State.handle_action(Action.call("p3", amount: 20))
      |> State.handle_action(Action.raise("p4", amount: 60))
      |> State.handle_action(Action.call("p1", amount: 50))
      |> State.handle_action(Action.call("p2", amount: 40))
      # p3 still needs to call the raise

    assert EventParser.everyone_has_acted_in_phase?(state, :preflop) == false
  end

  test "when everyone has called the raises we can move to the next round" do
    state = 
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3", "p4"])
      |> State.handle_action(Action.call("p1", amount: 10))
      |> State.handle_action(Action.call("p2", amount: 20))
      |> State.handle_action(Action.call("p3", amount: 20))
      |> State.handle_action(Action.raise("p4", amount: 60))
      |> State.handle_action(Action.call("p1", amount: 50))
      |> State.handle_action(Action.call("p2", amount: 40))
      |> State.handle_action(Action.call("p3", amount: 40))

    assert EventParser.everyone_has_acted_in_phase?(state, :preflop) == true
  end
end
