defmodule Poker.HandTest do
  use ExUnit.Case
  
  test 'cards can be added to a hand' do
    hand 
      = Poker.Hand.new
      |> Poker.Hand.add_card(%Poker.Card{value: 3, suit: :spades})

    assert hand.cards == [%Poker.Card{value: 3, suit: :spades}]
  end

  test 'you cannot give a hand more than five cards' do
    hand 
      = Poker.Hand.new
      |> Poker.Hand.add_card(%Poker.Card{value: 3, suit: :spades})
      |> Poker.Hand.add_card(%Poker.Card{value: 4, suit: :spades})
      |> Poker.Hand.add_card(%Poker.Card{value: 5, suit: :spades})
      |> Poker.Hand.add_card(%Poker.Card{value: 6, suit: :spades})
      |> Poker.Hand.add_card(%Poker.Card{value: 7, suit: :spades})


    assert_raise(Poker.Hand.TooManyCardsError, fn ->
      hand |> Poker.Hand.add_card(%Poker.Card{value: 8, suit: :spades})
    end)
  end

  test 'it can be asked its value' do
    hand 
      = Poker.Hand.new
      |> Poker.Hand.add_card(%Poker.Card{value: 3, suit: :spades})
      |> Poker.Hand.add_card(%Poker.Card{value: 4, suit: :spades})
      |> Poker.Hand.add_card(%Poker.Card{value: 5, suit: :spades})
      |> Poker.Hand.add_card(%Poker.Card{value: 6, suit: :spades})
      |> Poker.Hand.add_card(%Poker.Card{value: 7, suit: :spades})

    
    assert Poker.Hand.value(hand) == %Poker.HandRank{type: :straight_flush, cards: [7,6,5,4,3]}
  end
end
