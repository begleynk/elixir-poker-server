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

    assert HandRank.compute(hand) == %HandRank{type: :high_card, cards: [13, 11, 8, 4, 2]}
  end

  test "Ace is the highest card" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :hearts, value: 4})
      |> Hand.add_card(%Card{suit: :clubs, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 8})
      |> Hand.add_card(%Card{suit: :hearts, value: 1})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :high_card, cards: [1, 11, 8, 4, 2]}
  end

  test "Hands can be pairs" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :hearts, value: 4})
      |> Hand.add_card(%Card{suit: :clubs, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 8})
      |> Hand.add_card(%Card{suit: :hearts, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :pair, cards: [2, 2, 11, 8, 4]}
  end

  test "The pair doesn't have to be the lowest card" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :hearts, value: 4})
      |> Hand.add_card(%Card{suit: :clubs, value: 8})
      |> Hand.add_card(%Card{suit: :hearts, value: 8})
      |> Hand.add_card(%Card{suit: :hearts, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :pair, cards: [8, 8, 11, 4, 2]}
  end

  test "Hands with a pair and an unpaired ace are ranker properly" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :hearts, value: 4})
      |> Hand.add_card(%Card{suit: :clubs, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 8})
      |> Hand.add_card(%Card{suit: :hearts, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 1})

    assert HandRank.compute(hand) == %HandRank{type: :pair, cards: [2, 2, 1, 8, 4]}
  end

  test "Hands can be three of a kind" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 2})
      |> Hand.add_card(%Card{suit: :clubs, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 8})
      |> Hand.add_card(%Card{suit: :hearts, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :three_of_a_kind, cards: [2, 2, 2, 11, 8]}
  end

  test "The three of a kind don't have to be the lowest card" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 8})
      |> Hand.add_card(%Card{suit: :clubs, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 8})
      |> Hand.add_card(%Card{suit: :diamonds, value: 8})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :three_of_a_kind, cards: [8, 8, 8, 11, 2]}
  end
  
  test "Hands can be straights" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :hearts, value: 1})
      |> Hand.add_card(%Card{suit: :spades, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 3})
      |> Hand.add_card(%Card{suit: :hearts, value: 4})
      |> Hand.add_card(%Card{suit: :hearts, value: 5})

    assert HandRank.compute(hand) == %HandRank{type: :straight, cards: [5, 4, 3, 2, 1]}
  end

  test "Straights can have an ace as the highest card" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :hearts, value: 10})
      |> Hand.add_card(%Card{suit: :hearts, value: 12})
      |> Hand.add_card(%Card{suit: :hearts, value: 1})
      |> Hand.add_card(%Card{suit: :hearts, value: 13})
      |> Hand.add_card(%Card{suit: :spades, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :straight, cards: [1, 13, 12, 11, 10]}
  end

  test "Hands can be a flush" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 2})
      |> Hand.add_card(%Card{suit: :spades, value: 3})
      |> Hand.add_card(%Card{suit: :spades, value: 4})
      |> Hand.add_card(%Card{suit: :spades, value: 11})
      |> Hand.add_card(%Card{suit: :spades, value: 9})

    assert HandRank.compute(hand) == %HandRank{type: :flush, cards: [11, 9, 4, 3, 2]}
  end

  test "Flushes can have an ace as the highest card" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 2})
      |> Hand.add_card(%Card{suit: :spades, value: 3})
      |> Hand.add_card(%Card{suit: :spades, value: 4})
      |> Hand.add_card(%Card{suit: :spades, value: 11})
      |> Hand.add_card(%Card{suit: :spades, value: 1})

    assert HandRank.compute(hand) == %HandRank{type: :flush, cards: [1, 11, 4, 3, 2]}
  end

  test "Hands can be a full house" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 4})
      |> Hand.add_card(%Card{suit: :clubs, value: 4})
      |> Hand.add_card(%Card{suit: :hearts, value: 4})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})
      |> Hand.add_card(%Card{suit: :diamonds, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :full_house, cards: [4, 4, 4, 11, 11]}
  end

  test "A full house can have three of the higher value card" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 4})
      |> Hand.add_card(%Card{suit: :clubs, value: 11})
      |> Hand.add_card(%Card{suit: :hearts, value: 4})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})
      |> Hand.add_card(%Card{suit: :diamonds, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :full_house, cards: [11, 11, 11, 4, 4]}
  end

  test "Hands can be four of a kind" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 2})
      |> Hand.add_card(%Card{suit: :clubs, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})
      |> Hand.add_card(%Card{suit: :diamonds, value: 2})

    assert HandRank.compute(hand) == %HandRank{type: :four_of_a_kind, cards: [2, 2, 2, 2, 11]}
  end

  test "The four of a kind don't have to be the lowest card" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 11})
      |> Hand.add_card(%Card{suit: :clubs, value: 11})
      |> Hand.add_card(%Card{suit: :hearts, value: 2})
      |> Hand.add_card(%Card{suit: :hearts, value: 11})
      |> Hand.add_card(%Card{suit: :diamonds, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :four_of_a_kind, cards: [11, 11, 11, 11, 2]}
  end

  test "Hands can be a straight flush" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 8})
      |> Hand.add_card(%Card{suit: :spades, value: 6})
      |> Hand.add_card(%Card{suit: :spades, value: 7})
      |> Hand.add_card(%Card{suit: :spades, value: 5})
      |> Hand.add_card(%Card{suit: :spades, value: 9})

    assert HandRank.compute(hand) == %HandRank{type: :straight_flush, cards: [9, 8, 7, 6, 5]}
  end

  test "Hands can be a royal flush" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 10})
      |> Hand.add_card(%Card{suit: :spades, value: 12})
      |> Hand.add_card(%Card{suit: :spades, value: 1})
      |> Hand.add_card(%Card{suit: :spades, value: 13})
      |> Hand.add_card(%Card{suit: :spades, value: 11})

    assert HandRank.compute(hand) == %HandRank{type: :royal_flush, cards: [1, 13, 12, 11, 10]}
  end

  test "Too few or too many cards will give an invalid score" do
    hand = Hand.new
      |> Hand.add_card(%Card{suit: :spades, value: 10})
      |> Hand.add_card(%Card{suit: :spades, value: 12})
      |> Hand.add_card(%Card{suit: :spades, value: 1})

    assert HandRank.compute(hand) == %HandRank{type: :invalid, cards: nil}
  end

  # Comparing ranks

  test "for two high cards, the highest card wins" do
    a = %HandRank{type: :high_card, cards: [8, 6, 4, 3, 2]}
    b = %HandRank{type: :high_card, cards: [10, 9, 7, 5, 3]}
  
    assert HandRank.compare([a,b]) == [b,a]
  end
 
  test "Ace is the highest card" do
    a = %HandRank{type: :high_card, cards: [1, 7, 6, 5, 4]}
    b = %HandRank{type: :high_card, cards: [10, 7, 6, 5, 4]}

    assert HandRank.compare([a,b]) == [a,b]
  end

  test "Pairs win high cards" do
    a = %HandRank{type: :high_card, cards: [1, 7, 6, 5, 4]}
    b = %HandRank{type: :pair, cards: [5, 13, 11, 7]}

    assert HandRank.compare([a,b]) == [b,a]
  end

  test "Highest pair wins" do
    a = %HandRank{type: :pair, cards: [3, 7, 5, 4, 2]}
    b = %HandRank{type: :pair, cards: [8, 7, 5, 4, 2]}
    c = %HandRank{type: :pair, cards: [9, 7, 5, 4, 2]}

    assert HandRank.compare([a,b,c]) == [c,b,a]
  end

  test "Ace is the higest pair" do
    a = %HandRank{type: :pair, cards: [1, 7, 5, 4, 2]}
    b = %HandRank{type: :pair, cards: [8, 7, 5, 4, 2]}
    c = %HandRank{type: :pair, cards: [9, 7, 5, 4, 2]}

    assert HandRank.compare([a,b,c]) == [a,c,b]
  end

  test "Three of a kind beats pairs" do
    a = %HandRank{type: :pair, cards: [1, 7, 5, 4, 2]}
    b = %HandRank{type: :three_of_a_kind, cards: [8, 11, 10]}
    c = %HandRank{type: :pair, cards: [9, 7, 5, 4, 2]}

    assert HandRank.compare([a,b,c]) == [b,a,c]
  end

  test "Straight beats three of a kind" do
    a = %HandRank{type: :three_of_a_kind, cards: [1, 1, 1, 11, 10]}
    b = %HandRank{type: :three_of_a_kind, cards: [8, 8, 8, 5, 4]}
    c = %HandRank{type: :straight, cards: [9, 8, 7, 6, 5]}

    assert HandRank.compare([a,c,b]) == [c,a,b]
  end

  test "Flush beats straight" do
    a = %HandRank{type: :three_of_a_kind, cards: [1, 1, 1, 11, 10]}
    b = %HandRank{type: :flush, cards: [8, 7, 5, 4, 3]}
    c = %HandRank{type: :straight, cards: [9, 8, 7, 6, 5]}

    assert HandRank.compare([a,c,b]) == [b,c,a]
  end

  test "Full house beats flush" do
    a = %HandRank{type: :full_house, cards: [1, 1, 1, 5, 5]}
    b = %HandRank{type: :flush, cards: [8, 7, 5, 4, 3]}
    c = %HandRank{type: :straight, cards: [9, 8, 7, 6, 5]}

    assert HandRank.compare([a,c,b]) == [a,b,c]
  end

  test "Four of a kind beats full house" do
    a = %HandRank{type: :full_house, cards: [1, 1, 1, 5, 5]}
    b = %HandRank{type: :flush, cards: [8, 7, 5, 4, 3]}
    c = %HandRank{type: :straight_flush, cards: [9, 8, 7, 6, 5]}

    assert HandRank.compare([a,c,b]) == [c,a,b]
  end

  test "Straight flush beats four of a kind" do
    a = %HandRank{type: :full_house, cards: [1, 1, 1, 5, 5]}
    b = %HandRank{type: :four_of_a_kind, cards: [8, 8, 8, 8, 4]}
    c = %HandRank{type: :straight_flush, cards: [9, 8, 7, 6, 5]}

    assert HandRank.compare([a,c,b]) == [c,b,a]
  end

  test "Royal flush beats straight flush" do
    a = %HandRank{type: :royal_flush, cards: [1, 13, 12, 11, 10]}
    b = %HandRank{type: :four_of_a_kind, cards: [8, 8, 8, 8, 4]}
    c = %HandRank{type: :straight_flush, cards: [9, 8, 7, 6, 5]}

    assert HandRank.compare([a,c,b]) == [a,c,b]
  end
end
