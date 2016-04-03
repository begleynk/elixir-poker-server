defmodule Poker.HandTest do
  use ExUnit.Case
  
  test 'cards can be added to a hand' do
    hand 
      = Poker.Hand.new
      |> Poker.Hand.add_card(%Poker.Card{value: 3, suit: :spade})

    assert hand.cards == [%Poker.Card{value: 3, suit: :spade}]
  end

  test 'you cannot give a hand more than five cards' do
    hand 
      = Poker.Hand.new
      |> Poker.Hand.add_card(%Poker.Card{value: 3, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{value: 4, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{value: 5, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{value: 6, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{value: 7, suit: :spade})


    assert_raise(Poker.Hand.TooManyCardsError, fn ->
      hand |> Poker.Hand.add_card(%Poker.Card{value: 8, suit: :spade})
    end)
  end
end
