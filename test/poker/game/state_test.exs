defmodule Poker.Game.StateTest do
  use ExUnit.Case

  alias Poker.Game.{Action, NextAction, State}

  test "the game state must be provided a game ID, blinds, and player IDs" do
    state = %State{} = State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3", "p4"])

    assert state.id == "game_id"
    assert state.players == ["p1", "p2", "p3", "p4"]
    assert state.positions == [
      {:small_blind, "p1", :playing},
      {:big_blind, "p2", :playing},
      {:"3", "p3", :playing},
      {:button, "p4", :playing},
    ]
    assert state.phase == :setup
    assert state.pot == 0
    assert state.active_bets == %{}
    assert state.pocket_cards == %{}
    assert %NextAction{
      player: "p1",
      type: :call_blind,
      actions: [:call, :sit_out],
      to_call: 10
    } = state.next_action
  end

  test "only the player specified in the next action can perform an action" do
    assert {:error, :out_of_turn} = 
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3"])
      |> State.handle_action(Action.call("p3", amount: 10))
  end

  test "only the specified actions in the next action can be performed" do
    assert {:error, :invalid_action} =
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3"])
      |> State.handle_action(Action.bet("p1", amount: 40))
  end

  test "can only call the specified amount" do
    assert {:error, :invalid_call} = 
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3"])
      |> State.handle_action(Action.call("p1", amount: 40))
  end

  test "the game makes sure the small blind gets paid first" do
    state = 
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3"])
      |> State.handle_action(Action.call("p1", amount: 10))

    assert state.phase == :setup
    assert state.pot == 10
    assert state.active_bets == %{ "p1" => 10 }
    assert %NextAction{
      player: "p2",
      type: :call_blind,
      actions: [:call, :sit_out],
      to_call: 20
    } = state.next_action
  end

  test "after big blind is called, pocket cards are dealt and we move to preflop" do
    state = 
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3"])
      |> State.handle_action(Action.call("p1", amount: 10))
      |> State.handle_action(Action.call("p2", amount: 20))

    assert state.phase == :preflop
    assert state.pot == 30
    assert state.active_bets == %{ "p1" => 10, "p2" => 20 }
    assert %NextAction{
      player: "p3",
      type: :call_bet,
      actions: [:call, :raise, :fold],
      to_call: 20
    } = state.next_action
    assert %{
      "p1" => {%Poker.Card{}, %Poker.Card{}},
      "p2" => {%Poker.Card{}, %Poker.Card{}},
      "p3" => {%Poker.Card{}, %Poker.Card{}},
    } = state.pocket_cards
  end

  test "heads up the first player to act preflop would be the small blind" do
    state = 
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2"])
      |> State.handle_action(Action.call("p1", amount: 10))
      |> State.handle_action(Action.call("p2", amount: 20))

    assert state.phase == :preflop
    assert state.pot == 30
    assert state.active_bets == %{ "p1" => 10, "p2" => 20 }
    assert %NextAction{
      player: "p1",
      type: :call_bet,
      actions: [:call, :raise, :fold],
      to_call: 10
    } = state.next_action
    assert %{
      "p1" => {%Poker.Card{}, %Poker.Card{}},
      "p2" => {%Poker.Card{}, %Poker.Card{}},
    } = state.pocket_cards
  end

  test "the blinds have to act last preflop" do
    assert %State{} = 
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3", "p4"])
      |> State.handle_action(Action.call("p1", amount: 10))
      |> State.handle_action(Action.call("p2", amount: 20))
      |> State.handle_action(Action.call("p3", amount: 20))
      |> State.handle_action(Action.call("p4", amount: 20))
      |> State.handle_action(Action.call("p1", amount: 10))
      |> State.handle_action(Action.check("p2"))
  end

  test "after preflop, the small blind acts first" do
    state =
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3", "p4"])
      |> State.handle_action(Action.call("p1", amount: 10))
      |> State.handle_action(Action.call("p2", amount: 20))
      |> State.handle_action(Action.call("p3", amount: 20))
      |> State.handle_action(Action.call("p4", amount: 20))
      |> State.handle_action(Action.call("p1", amount: 10))
      |> State.handle_action(Action.check("p2"))

    assert state.phase == :flop
    assert state.pot == 80
    assert state.active_bets == %{}
    assert %NextAction{
      player: "p1",
      type: :regular_action,
      actions: [:check, :bet, :fold]
    } = state.next_action
    assert [%Poker.Card{}, %Poker.Card{}, %Poker.Card{}] = state.community_cards
  end

  test "raises must be called preflop" do
    state =
      State.new(id: "game_id", small_blind: 10, big_blind: 20, players: ["p1", "p2", "p3", "p4"])
      |> State.handle_action(Action.call("p1", amount: 10))
      |> State.handle_action(Action.call("p2", amount: 20))
      |> State.handle_action(Action.raise("p3", amount: 60))

    assert state.pot == 90
    assert %NextAction{
      player: "p4",
      type: :call_bet,
      to_call: 60,
      actions: [:call, :raise, :fold]
    } = state.next_action

    state = state |> State.handle_action(Action.call("p4", amount: 60)) 

    assert state.pot == 150
    assert %NextAction{
      player: "p1",
      type: :call_bet,
      to_call: 50,
      actions: [:call, :raise, :fold]
    } = state.next_action

    state = state |> State.handle_action(Action.raise("p1", amount: 150)) 

    assert state.pot == 300
    assert %NextAction{
      player: "p2",
      type: :call_bet,
      to_call: 130,
      actions: [:call, :raise, :fold]
    } = state.next_action

    state = state |> State.handle_action(Action.fold("p2"))

    assert state.pot == 300
    assert %NextAction{
      player: "p3",
      type: :call_bet,
      to_call: 90,
      actions: [:call, :raise, :fold]
    } = state.next_action

    state = state |> State.handle_action(Action.fold("p3"))

    assert state.pot == 300
    assert %NextAction{
      player: "p4",
      type: :call_bet,
      to_call: 90,
      actions: [:call, :raise, :fold]
    } = state.next_action

    state = state |> State.handle_action(Action.call("p4", amount: 90))

    assert state.pot == 390
    assert state.phase == :flop
    assert %NextAction{
      player: "p1",
      type: :regular_action,
      actions: [:check, :bet, :fold]
    } = state.next_action

    state = state |> State.handle_action(Action.bet("p1", amount: 200))

    assert state.pot == 590
    assert state.phase == :flop
    assert %NextAction{
      player: "p4",
      type: :call_bet,
      to_call: 200,
      actions: [:call, :raise, :fold]
    } = state.next_action

    state = state |> State.handle_action(Action.fold("p4"))
  end
end
