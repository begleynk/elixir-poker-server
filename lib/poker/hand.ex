defmodule Poker.Hand do
  defstruct cards: []

  alias Poker.{Hand, HandRank, Card}

  defmodule TooManyCardsError do
    defexception message: 'Cannot add more cards into hand'
  end

  def new do
    %Hand{}
  end

  def add_card(%Hand{ cards: cards }, %Card{}) when length(cards) >= 5 do
    raise TooManyCardsError
  end

  def add_card(%Hand{} = hand, %Card{} = card) do
    %Hand{ hand | cards: [card | hand.cards] }
  end

  def value(%Hand{} = hand) do
    HandRank.compute(hand)
  end
end

