defmodule Poker.HandTest do
  use ExUnit.Case
  
  test 'cards can be added to a hand' do
    hand 
      = Poker.Hand.new
      |> Poker.Hand.add_card(%Poker.Card{rank: 3, suit: :spade})

    assert hand.cards == [%Poker.Card{rank: 3, suit: :spade}]
  end

  test 'you cannot give a hand more than five cards' do
    hand 
      = Poker.Hand.new
      |> Poker.Hand.add_card(%Poker.Card{rank: 3, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{rank: 4, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{rank: 5, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{rank: 6, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{rank: 7, suit: :spade})


    assert_raise(Poker.Hand.TooManyCardsError, fn ->
      hand |> Poker.Hand.add_card(%Poker.Card{rank: 8, suit: :spade})
    end)
  end

  test 'a hand does not have a value with fewer than 5 cards' do
    hand 
      = Poker.Hand.new
      |> Poker.Hand.add_card(%Poker.Card{rank: 3, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{rank: 4, suit: :spade})


    assert Poker.Hand.value(hand) == :invalid
  end

  test 'a hand can tell you its value when it had 5 cards' do
    hand 
      = Poker.Hand.new
      |> Poker.Hand.add_card(%Poker.Card{rank: 3, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{rank: 4, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{rank: 5, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{rank: 6, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{rank: 7, suit: :spade})


    assert Poker.Hand.value(hand) == %Poker.HandRank{type: :straight_flush, high_cards: [7]}
  end
end
