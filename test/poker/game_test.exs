defmodule Poker.GameTest do
  use ExUnit.Case

  alias Poker.{Player, Game, Card}

  test "a game can start with two or more players" do
    {:ok, player1} = Player.start_link("player_id_1")
    {:ok, player2} = Player.start_link("player_id_2")

    assert {:ok, game} = Game.start_link(["player_id_1", "player_id_2"], {100, 200}, "game_foo")
    assert Game.players(game) == [Player.info(player1), Player.info(player2)]
    assert Game.blinds(game) == {100, 200}
  end

  test "a game cannot start with fewer than two players" do
    {:ok, player1} = Player.start_link("player_id_1")

    assert {:error, :not_enough_players} = Game.start_link([player1], {100, 200}, "game_foo")
  end

  test 'a basic full round' do
    {:ok, player1} = Player.start_link("player_id_1")
    {:ok, player2} = Player.start_link("player_id_2")
    {:ok, player3} = Player.start_link("player_id_3")

    assert {:ok, game} = Game.start_link(["player_id_1", "player_id_2", "player_id_3"], {100, 200}, "game_foo")

    state = Game.state(game)
    assert state.phase == :setup
    assert state.total_pot == 0
    assert state.next_action == %Game.NextAction{
      player: "player_id_1",
      type: :post_blind,
      to_call: 100,
      actions: [:call, :sit_out]
    }

    :ok = player1 |> Player.perform_action("game_foo", Game.Event.call(amount: 100))

    state = Game.state(game)
    assert state.phase == :setup
    assert state.total_pot == 100
    assert state.next_action == %Game.NextAction{
      player: "player_id_2",
      type: :post_blind,
      to_call: 200,
      actions: [:call, :sit_out]
    }

    :ok = player2 |> Player.perform_action("game_foo", Game.Event.call(amount: 200))

    state = Game.state(game)
    assert state.phase == :preflop
    assert state.total_pot == 300
    assert %{
      "player_id_1" => {%Card{}, %Card{}},
      "player_id_2" => {%Card{}, %Card{}},
      "player_id_3" => {%Card{}, %Card{}},
    } = state.pocket_cards
    assert state.next_action == %Game.NextAction{
      player: "player_id_3",
      type: :answer_bet,
      to_call: 200,
      actions: [:call, :raise, :fold]
    }

    :ok = player3 |> Player.perform_action("game_foo", Game.Event.call(amount: 200))

    state = Game.state(game)
    assert state.phase == :preflop
    assert state.total_pot == 500
    assert state.next_action == %Game.NextAction{
      player: "player_id_1",
      type: :answer_bet,
      to_call: 100,
      actions: [:call, :raise, :fold]
    }

    :ok = player1 |> Player.perform_action("game_foo", Game.Event.raise(amount: 600))

    state = Game.state(game)
    assert state.phase == :preflop
    assert state.total_pot == 1100
    assert state.next_action == %Game.NextAction{
      player: "player_id_2",
      type: :answer_bet,
      to_call: 400,
      actions: [:call, :raise, :fold]
    }

    assert :ok == player2 |> Player.perform_action(
      "game_foo",
      Game.Event.fold
    )

    state = Game.state(game)
    assert [_,{"player_id_2", :big_blind, :folded}, _] = state.players
    assert state.total_pot == 1100
    assert state.next_action == %Game.NextAction{
      player: "player_id_3",
      type: :answer_bet,
      to_call: 400,
      actions: [:call, :raise, :fold]
    }

    assert :ok == player3 |> Player.perform_action("game_foo", Game.Event.fold)

    state = Game.state(game)
    assert [_,_,{"player_id_3", :button, :folded}] = state.players
    assert state.total_pot == 1100
    assert state.next_action == nil
    assert state.phase == :showdown
    assert state.winner == "player_id_1"
  end

  test 'going to the flop' do
    {:ok, player1} = Player.start_link("player_id_1")
    {:ok, player2} = Player.start_link("player_id_2")
    {:ok, player3} = Player.start_link("player_id_3")

    assert {:ok, game} = Game.start_link(["player_id_1", "player_id_2", "player_id_3"], {100, 200}, "game_foo")

    # call small blind
    :ok = player1 |> Player.perform_action("game_foo", Game.Event.call(amount: 100))

    state = Game.state(game)
    assert state.phase == :setup

    # call big blind
    :ok = player2 |> Player.perform_action("game_foo", Game.Event.call(amount: 200))

    state = Game.state(game)
    assert state.phase == :preflop

    # button call 
    :ok = player3 |> Player.perform_action("game_foo", Game.Event.call(amount: 200))

    state = Game.state(game)
    assert state.phase == :preflop

    # sb call 
    :ok = player1 |> Player.perform_action("game_foo", Game.Event.call(amount: 200))

    state = Game.state(game)
    assert state.phase == :preflop
    assert state.next_action == %Game.NextAction{
      player: "player_id_2",
      type: :answer_bet,
      to_call: 0,
      actions: [:check, :raise, :fold]
    }

    # bb check 
    :ok = player2 |> Player.perform_action("game_foo", Game.Event.check)

    state = Game.state(game)
    assert %{
      "player_id_1" => {%Card{}, %Card{}},
      "player_id_2" => {%Card{}, %Card{}},
      "player_id_3" => {%Card{}, %Card{}},
    } = state.pocket_cards
    assert [
      %Card{}, 
      %Card{}, 
      %Card{}
    ] = state.community_cards
    assert state.phase == :flop
    assert state.next_action == %Game.NextAction{
      player: "player_id_3",
      type: :regular_action,
      to_call: 0,
      actions: [:check, :bet, :fold]
    }
  end
end
