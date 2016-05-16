defmodule Poker.GameTest do
  use ExUnit.Case

  alias Poker.{Player, Game}

  test "a game can start with two or more players" do
    {:ok, player1} = Player.start_link("player_id_1")
    {:ok, player2} = Player.start_link("player_id_2")

    assert {:ok, game} = Game.start_link([player1, player2], {100, 200}, "game_foo")
    assert Game.players(game) == [Player.info(player1), Player.info(player2)]
    assert Game.blinds(game) == {100, 200}
  end

  test "a game cannot start with fewer than two players" do
    {:ok, player1} = Player.start_link("player_id_1")

    assert {:error, :not_enough_players} = Game.start_link([player1], {100, 200}, "game_foo")
  end

  test 'players must post blinds for the round to start' do
    {:ok, player1} = Player.start_link("player_id_1")
    {:ok, player2} = Player.start_link("player_id_2")
    {:ok, player3} = Player.start_link("player_id_3")

    assert {:ok, game} = Game.start_link([player1, player2, player3, self], {100, 200}, "game_foo")

    assert Game.whereis("game_foo") |> Game.next_action == %Game.NextAction{
      player: player1,
      type: :post_blind,
      to_call: 100,
      actions: [:call, :sit_out]
    }

    assert :ok == player1 |> Player.perform_action(
      "game_foo", 
      Game.Action.call(amount: 100)
    )

    assert Game.next_action(game) == %Game.NextAction{
      player: player2,
      type: :post_blind,
      to_call: 200,
      actions: [:call, :sit_out]
    }
  end
end
