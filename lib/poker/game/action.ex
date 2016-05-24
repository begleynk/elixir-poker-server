defmodule Poker.Game.Action do
  defstruct [
    type: nil,
    player: nil,
    amount: nil
  ]

  def call(player_id, amount: amount) do
    %Poker.Game.Action{
      type: :call,
      player: player_id,
      amount: amount
    }
  end

  def bet(player_id, amount: amount) do
    %Poker.Game.Action{
      type: :bet,
      player: player_id,
      amount: amount
    }
  end

  def raise(player_id, amount: amount) do
    %Poker.Game.Action{
      type: :raise,
      player: player_id,
      amount: amount
    }
  end

  def check(player_id) do
    %Poker.Game.Action{
      type: :check,
      player: player_id,
    }
  end

  def fold(player_id) do
    %Poker.Game.Action{
      type: :fold,
      player: player_id,
    }
  end
end
