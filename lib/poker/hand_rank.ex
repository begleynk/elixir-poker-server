defmodule Poker.HandRank do
  defstruct type: nil, high_cards: []

  alias Poker.{Card, Hand, HandRank}

  def compute(%Hand{ cards: cards }) when length(cards) != 5 do
    %HandRank{type: :invalid, high_cards: nil}
  end

  def compute(%Hand{ cards: cards}) do
    cards
      |> sort_by_value # Very important to first sort the cards
      |> compute_score
  end

  # Match full houses - eg. 2,2,2 3,3
  # The high card is determined by the group of three
  def compute_score([%Card{value: value}, %Card{value: value}, %Card{value: value}, 
                     %Card{value: other_value}, %Card{value: other_value}]) do
    %HandRank{type: :full_house, high_cards: [value, other_value]}
  end

  # Match full houses where there are three cards
  # of higher value - e.g. 8,8,8 2,2
  def compute_score([%Card{value: value}, %Card{value: value}, 
                     %Card{value: other_value}, %Card{value: other_value}, %Card{value: other_value}]) do
    %HandRank{type: :full_house, high_cards: [other_value, value]}
  end

  # Match a royal flush
  def compute_score([%Card{suit: suit, value: 1}, %Card{suit: suit, value: 10}, 
                     %Card{suit: suit, value: 11}, %Card{suit: suit, value: 12}, 
                     %Card{suit: suit, value: 13}]),
       do: %HandRank{type: :royal_flush, high_cards: [1]}

  # Match a straight flush - anything but a royal flush
  def compute_score([%Card{suit: suit, value: first}, %Card{suit: suit, value: second}, 
                     %Card{suit: suit, value: third}, %Card{suit: suit, value: fourth}, 
                     %Card{suit: suit, value: fifth}]) 
       when ((first == second - 1) and
             (second == third - 1) and
             (third == fourth - 1) and
             (fourth == fifth - 1)
       ), 
       do: %HandRank{type: :straight_flush, high_cards: [fifth]}

  # Match straights where ace is a high card
  def compute_score([%Card{value: 1}, %Card{value: 10}, %Card{value: 11},
                     %Card{value: 12}, %Card{value: 13}]),
       do: %HandRank{type: :straight, high_cards: [1]}

  # Match all other straights
  def compute_score([%Card{value: first}, %Card{value: second}, %Card{value: third},
                     %Card{value: fourth}, %Card{value: fifth}]) 
       when ((first == second - 1) and
             (second == third - 1) and
             (third == fourth - 1) and
             (fourth == fifth - 1)
       ), 
       do: %HandRank{type: :straight, high_cards: [fifth]}

  # Match flushes with an ace high card
  def compute_score([%Card{value: 1, suit: suit}, %Card{value: value1, suit: suit}, 
                     %Card{value: value2, suit: suit}, %Card{value: value3, suit: suit}, 
                     %Card{value: value4, suit: suit}]) do
    %HandRank{type: :flush, high_cards: [1, value4, value3, value2, value1]}
  end

  # Match all other flushes
  def compute_score([%Card{value: val1, suit: suit}, %Card{value: val2, suit: suit}, 
                     %Card{value: val3, suit: suit}, %Card{value: val4, suit: suit}, 
                     %Card{value: highest, suit: suit}]) do
    %HandRank{type: :flush, high_cards: [highest, val4, val3, val2, val1]}
  end

  # Match an ace high card
  def compute_score([%Card{value: 1}, %Card{value: second}, %Card{value: third},
                     %Card{value: fourth}, %Card{value: fifth}])
       when ((second != 1) and
             (second != third) and
             (third != fourth) and
             (fourth != fifth)
       ), 
       do: %HandRank{type: :high_card, high_cards: [1, fifth, fourth, third, second]}

  # Match any other high card
  def compute_score([%Card{value: first}, %Card{value: second}, %Card{value: third},
                     %Card{value: fourth}, %Card{value: fifth}])
       when ((first != second) and
             (second != third) and
             (third != fourth) and
             (fourth != fifth)
       ), 
       do: %HandRank{type: :high_card, high_cards: [fifth, fourth, third, second, first]}

  # Match pairs, three of a kinds and four of a kinds
  def compute_score(cards) do
    case group_by_value_count(cards) do
      [{2, high_card} | rest] -> 
        %HandRank{type: :pair, high_cards: [high_card] ++ (rest |> Enum.map(fn {_, v} -> v end))}
      [{3, high_card} | rest] -> 
        %HandRank{type: :three_of_a_kind, high_cards: [high_card] ++  (rest |> Enum.map(fn {_, v} -> v end))}
      [{4, high_card} | rest] -> 
      %HandRank{type: :four_of_a_kind, high_cards: [high_card] ++ (rest |> Enum.map(fn {_, v} -> v end))}
    end
  end

  defp sort_by_value(cards) do
    cards |> Enum.sort(&(&1.value < &2.value))
  end

  defp group_by_value_count(cards) do
    cards
    |> Enum.group_by(&(&1.value))
    |> Enum.map(fn({value, cards}) ->
         {length(cards), value}
       end)
    |> Enum.sort(fn({count, value}, {count2, value2}) -> 
         count > count2 || value > value2 
       end)
  end
end
