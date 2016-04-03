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

  test 'it can be asked its value' do
    hand 
      = Poker.Hand.new
      |> Poker.Hand.add_card(%Poker.Card{value: 3, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{value: 4, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{value: 5, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{value: 6, suit: :spade})
      |> Poker.Hand.add_card(%Poker.Card{value: 7, suit: :spade})

    
    assert Poker.Hand.value(hand) == %Poker.HandRank{type: :straight_flush, cards: [7,6,5,4,3]}
  end
end
