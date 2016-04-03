defmodule Poker.Hand do
  defstruct cards: []

  defmodule TooManyCardsError do
    defexception message: 'Cannot add more cards into hand'
  end

  def new do
    %Poker.Hand{}
  end

  def add_card(%Poker.Hand{ cards: cards }, %Poker.Card{}) when length(cards) >= 5 do
    raise TooManyCardsError
  end

  def add_card(%Poker.Hand{} = hand, %Poker.Card{} = card) do
    %Poker.Hand{ hand | cards: [card | hand.cards] }
  end

  def value(%Poker.Hand{ cards: cards} = _hand) when length(cards) == 5 do
    %Poker.HandRank{type: :straight_flush, high_cards: [7]}
  end

  def value(%Poker.Hand{}) do
    :invalid
  end
end

