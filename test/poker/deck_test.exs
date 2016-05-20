defmodule Poker.DeckTest do
  use ExUnit.Case

  alias Poker.Deck

  test "create a deck with 52 cards" do
    deck = Deck.new

    assert Deck.cards_left(deck) == 52
  end

  test "you can draw a card from the deck" do
    deck = Deck.new

    assert {:ok, %Poker.Card{suit: _, value: _}, deck} = Deck.draw_card(deck)
    assert Deck.cards_left(deck) == 51
  end

  test "you can draw more than one card" do
    deck = Deck.new

    assert {:ok, 
            [
              %Poker.Card{suit: _, value: _},
              %Poker.Card{suit: _, value: _},
              %Poker.Card{suit: _, value: _}
            ],
            deck} = Deck.draw_cards(deck, 3)

    assert Deck.cards_left(deck) == 49
  end

  test "it tells you if it runs out of cards" do
    deck = Enum.reduce(1..50, Deck.new, fn(_, deck) ->
      {:ok, _, deck} = Deck.draw_card(deck)
      deck
    end)

    assert Deck.cards_left(deck) == 2
    {:error, :not_enough_cards, new_deck} = Deck.draw_cards(deck, 5)
    assert Deck.cards_left(new_deck) == 2
  end

  test "it tells you if it runs out of cards when drawing multiple cards" do
    deck = Enum.reduce(1..52, Deck.new, fn(_, deck) ->
      {:ok, _, deck} = Deck.draw_card(deck)
      deck
    end)

    assert Deck.cards_left(deck) == 0
    assert Deck.draw_card(deck) == {:error, :empty_deck, deck}
  end

  test "the card is removed from the deck after drawing" do
    deck = Deck.new
    {:ok, card, deck} = Deck.draw_card(deck)

    assert Deck.has_card?(deck, card) == false
  end
end

