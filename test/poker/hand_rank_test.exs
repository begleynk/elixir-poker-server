defmodule Poker.HandRankTest do
  use ExUnit.Case 

  alias Poker.{Hand, HandRank, Card}

  test "Hands can just have a high card" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :hearts, value: 4})
      |> Hand.add_card(%Card{suit: :clubs, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 8})
      |> Hand.add_card(%Card{suit: :hearts, value: 13})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :high_card, high_cards: [13, 11, 8, 4, 2]}
  end

  test "Ace is the highest card" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :hearts, value: 4})
      |> Hand.add_card(%Card{suit: :clubs, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 8})
      |> Hand.add_card(%Card{suit: :hearts, value: 1})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :high_card, high_cards: [1, 11, 8, 4, 2]}
  end

  test "Hands can be pairs" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :hearts, value: 4})
      |> Hand.add_card(%Card{suit: :clubs, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 8})
      |> Hand.add_card(%Card{suit: :hearts, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :pair, high_cards: [2, 11, 8, 4]}
  end

  test "The pair doesn't have to be the lowest card" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :hearts, value: 4})
      |> Hand.add_card(%Card{suit: :clubs, value: 8})
      |> Hand.add_card(%Card{suit: :hearts, value: 8})
      |> Hand.add_card(%Card{suit: :hearts, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :pair, high_cards: [8, 11, 4, 2]}
  end

  test "Hands can be three of a kind" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 2})
      |> Hand.add_card(%Card{suit: :clubs, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 8})
      |> Hand.add_card(%Card{suit: :hearts, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :three_of_a_kind, high_cards: [2, 11, 8]}
  end

  test "The three of a kind don't have to be the lowest card" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 8})
      |> Hand.add_card(%Card{suit: :clubs, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 8})
      |> Hand.add_card(%Card{suit: :diamonds, value: 8})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :three_of_a_kind, high_cards: [8, 11, 2]}
  end
  
  test "Hands can be straights" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :hearts, value: 1})
      |> Hand.add_card(%Card{suit: :spades, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 3})
      |> Hand.add_card(%Card{suit: :hearts, value: 4})
      |> Hand.add_card(%Card{suit: :hearts, value: 5})

    assert HandRank.compute(hand) == %HandRank{type: :straight, high_cards: [5]}
  end

  test "Straights can have an ace as the highest card" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :hearts, value: 10})
      |> Hand.add_card(%Card{suit: :hearts, value: 12})
      |> Hand.add_card(%Card{suit: :hearts, value: 1})
      |> Hand.add_card(%Card{suit: :hearts, value: 13})
      |> Hand.add_card(%Card{suit: :spades, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :straight, high_cards: [1]}
  end

  test "Hands can be a flush" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 2})
      |> Hand.add_card(%Card{suit: :spades, value: 3})
      |> Hand.add_card(%Card{suit: :spades, value: 4})
      |> Hand.add_card(%Card{suit: :spades, value: 11})
      |> Hand.add_card(%Card{suit: :spades, value: 9})

    assert HandRank.compute(hand) == %HandRank{type: :flush, high_cards: [11, 9, 4, 3, 2]}
  end

  test "Flushes can have an ace as the highest card" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 2})
      |> Hand.add_card(%Card{suit: :spades, value: 3})
      |> Hand.add_card(%Card{suit: :spades, value: 4})
      |> Hand.add_card(%Card{suit: :spades, value: 11})
      |> Hand.add_card(%Card{suit: :spades, value: 1})

    assert HandRank.compute(hand) == %HandRank{type: :flush, high_cards: [1, 11, 4, 3, 2]}
  end

  test "Hands can be a full house" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 4})
      |> Hand.add_card(%Card{suit: :clubs, value: 4})
      |> Hand.add_card(%Card{suit: :hearts, value: 4})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})
      |> Hand.add_card(%Card{suit: :diamonds, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :full_house, high_cards: [4, 11]}
  end

  test "A full house can have three of the higher value card" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 4})
      |> Hand.add_card(%Card{suit: :clubs, value: 11})
      |> Hand.add_card(%Card{suit: :hearts, value: 4})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})
      |> Hand.add_card(%Card{suit: :diamonds, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :full_house, high_cards: [11, 4]}
  end

  test "Hands can be four of a kind" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 2})
      |> Hand.add_card(%Card{suit: :clubs, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})
      |> Hand.add_card(%Card{suit: :diamonds, value: 2})

    assert HandRank.compute(hand) == %HandRank{type: :four_of_a_kind, high_cards: [2, 11]}
  end

  test "The four of a kind don't have to be the lowest card" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 11})
      |> Hand.add_card(%Card{suit: :clubs, value: 11})
      |> Hand.add_card(%Card{suit: :hearts, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})
      |> Hand.add_card(%Card{suit: :diamonds, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :four_of_a_kind, high_cards: [11, 2]}
  end

  test "Hands can be a straight flush" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 8})
      |> Hand.add_card(%Card{suit: :spades, value: 6})
      |> Hand.add_card(%Card{suit: :spades, value: 7})
      |> Hand.add_card(%Card{suit: :spades, value: 5})
      |> Hand.add_card(%Card{suit: :spades, value: 9})

    assert HandRank.compute(hand) == %HandRank{type: :straight_flush, high_cards: [9]}
  end

  test "Hands can be a royal flush" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 10})
      |> Hand.add_card(%Card{suit: :spades, value: 12})
      |> Hand.add_card(%Card{suit: :spades, value: 1})
      |> Hand.add_card(%Card{suit: :spades, value: 13})
      |> Hand.add_card(%Card{suit: :spades, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :royal_flush, high_cards: [1]}
  end

  test "Too few or too many cards will give an invalid score" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 10})
      |> Hand.add_card(%Card{suit: :spades, value: 12})
      |> Hand.add_card(%Card{suit: :spades, value: 1})

    assert HandRank.compute(hand) == %HandRank{type: :invalid, high_cards: nil}
  end
end
