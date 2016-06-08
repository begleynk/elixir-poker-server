defmodule Poker.Game.VisibilityFilterTest do
  use ExUnit.Case

  alias Poker.Game.{State, Action, VisibilityFilter}

  setup do
    state =
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3", "p4"])
      |> State.handle_action(Action.call("p1", amount: 10)) # Call SB
      |> State.handle_action(Action.call("p2", amount: 20)) # Call BB
      |> State.handle_action(Action.call("p3", amount: 20))
      |> State.handle_action(Action.call("p4", amount: 20))
      |> State.handle_action(Action.call("p1", amount: 10))
      |> State.handle_action(Action.check("p2")) # Move to Flop
      |> State.handle_action(Action.check("p1"))
      |> State.handle_action(Action.check("p2"))

    {:ok, state: state}
  end

  test "an administrator can see the whole state", %{ state: state } do
    assert VisibilityFilter.filter_state(state, :admin) == state
  end

  test "anyone can see the public information of the game", %{ state: state } do
    visible_state = VisibilityFilter.filter_state(state, :public)

    assert state.id == visible_state.id
    assert state.players == visible_state.players
    assert state.small_blind == visible_state.small_blind
    assert state.big_blind == visible_state.big_blind
    assert state.positions == visible_state.positions
    assert state.community_cards == visible_state.community_cards
    assert state.pot == visible_state.pot
    assert state.next_action == visible_state.next_action

    assert visible_state.pocket_cards == nil
    assert visible_state.hand_value == nil
  end

  test "filtered state holds public information about the game", %{ state: state } do
    visible_state = VisibilityFilter.filter_state(state, "p1")

    assert state.id == visible_state.id
    assert state.players == visible_state.players
    assert state.small_blind == visible_state.small_blind
    assert state.big_blind == visible_state.big_blind
    assert state.positions == visible_state.positions
    assert state.community_cards == visible_state.community_cards
    assert state.pot == visible_state.pot
    assert state.next_action == visible_state.next_action
  end

  test "players in the game can only see their hands", %{ state: state } do
    visible_state = VisibilityFilter.filter_state(state, "p1")

    assert state.pocket_cards["p1"] == visible_state.pocket_cards
  end

  test "players can only see the value of their own hand", %{ state: state } do
    visible_state = VisibilityFilter.filter_state(state, "p1")

    assert state.hand_values["p1"] == visible_state.hand_value
  end

  test "at showdown other hands will be revealed" do
    state =
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3", "p4"])
      |> State.handle_action(Action.call("p1", amount: 10)) # Call SB
      |> State.handle_action(Action.call("p2", amount: 20)) # Call BB
      |> State.handle_action(Action.call("p3", amount: 20))
      |> State.handle_action(Action.call("p4", amount: 20))
      |> State.handle_action(Action.call("p1", amount: 10))
      |> State.handle_action(Action.check("p2")) # Move to Flop
      |> State.handle_action(Action.check("p1"))
      |> State.handle_action(Action.check("p2"))
      |> State.handle_action(Action.check("p3"))
      |> State.handle_action(Action.check("p4")) # Move to Turn
      |> State.handle_action(Action.check("p1"))
      |> State.handle_action(Action.check("p2"))
      |> State.handle_action(Action.check("p3"))
      |> State.handle_action(Action.check("p4")) # Move to River
      |> State.handle_action(Action.check("p1"))
      |> State.handle_action(Action.check("p2"))
      |> State.handle_action(Action.check("p3"))
      |> State.handle_action(Action.check("p4")) # Move to Showdown

    visible_state = VisibilityFilter.filter_state(state, "p1")

    assert state.hand_values["p1"] == visible_state.hand_value
    assert [
      {:small_blind, "p1", :playing, {%Poker.Card{}, %Poker.Card{}}, %Poker.HandRank{}}, 
      {:big_blind, "p2", :playing, {%Poker.Card{}, %Poker.Card{}}, %Poker.HandRank{}},
      {:"3", "p3", :playing, {%Poker.Card{}, %Poker.Card{}}, %Poker.HandRank{}}, 
      {:button, "p4", :playing, {%Poker.Card{}, %Poker.Card{}}, %Poker.HandRank{}}
    ] = visible_state.positions
  end
end
