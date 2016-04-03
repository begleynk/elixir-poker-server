defmodule Poker.HandRank do
  defstruct type: nil, cards: []

  @type_rankings [:high_card, :pair, :three_of_a_kind, 
                  :straight, :flush, :full_house, 
                  :four_of_a_kind, :straight_flush, :royal_flush]

  alias Poker.{Card, Hand, HandRank}

  def compute(%Hand{ cards: cards }) when length(cards) != 5 do
    %HandRank{type: :invalid, cards: nil}
  end

  def compute(%Hand{ cards: cards}) do
    cards
      |> sort_by_value # Very important to first sort the cards
      |> compute_score
  end

  def compare(ranks) do
    ranks
      |> group_by_types
      |> rank_groups_by_types
      |> rank_each_group_by_high_card
      |> flatten
  end

  #********* Implementations ********#

  # Match full houses - eg. 2,2,2 3,3
  # The high card is determined by the group of three
  defp compute_score([%Card{value: value}, %Card{value: value}, %Card{value: value}, 
                     %Card{value: other_value}, %Card{value: other_value}]) do
    %HandRank{type: :full_house, cards: [value, value, value, other_value, other_value]}
  end

  # Match full houses where there are three cards
  # of higher value - e.g. 8,8,8 2,2
  defp compute_score([%Card{value: value}, %Card{value: value}, 
                     %Card{value: other_value}, %Card{value: other_value}, %Card{value: other_value}]) do
    %HandRank{type: :full_house, cards: [other_value, other_value, other_value, value, value]}
  end

  # Match a royal flush
  defp compute_score([%Card{suit: suit, value: 1}, %Card{suit: suit, value: 10}, 
                     %Card{suit: suit, value: 11}, %Card{suit: suit, value: 12}, 
                     %Card{suit: suit, value: 13}]),
       do: %HandRank{type: :royal_flush, cards: [1, 13, 12, 11, 10]}

  # Match a straight flush - anything but a royal flush
  defp compute_score([%Card{suit: suit, value: first}, %Card{suit: suit, value: second}, 
                     %Card{suit: suit, value: third}, %Card{suit: suit, value: fourth}, 
                     %Card{suit: suit, value: fifth}]) 
       when ((first == second - 1) and
             (second == third - 1) and
             (third == fourth - 1) and
             (fourth == fifth - 1)
       ), 
       do: %HandRank{type: :straight_flush, cards: [fifth, fourth, third, second, first]}

  # Match straights where ace is a high card
  defp compute_score([%Card{value: 1}, %Card{value: 10}, %Card{value: 11},
                     %Card{value: 12}, %Card{value: 13}]),
       do: %HandRank{type: :straight, cards: [1, 13, 12, 11, 10]}

  # Match all other straights
  defp compute_score([%Card{value: first}, %Card{value: second}, %Card{value: third},
                     %Card{value: fourth}, %Card{value: fifth}]) 
       when ((first == second - 1) and
             (second == third - 1) and
             (third == fourth - 1) and
             (fourth == fifth - 1)
       ), 
       do: %HandRank{type: :straight, cards: [fifth, fourth, third, second, first]}

  # Match flushes with an ace high card
  defp compute_score([%Card{value: 1, suit: suit}, %Card{value: value1, suit: suit}, 
                     %Card{value: value2, suit: suit}, %Card{value: value3, suit: suit}, 
                     %Card{value: value4, suit: suit}]) do
    %HandRank{type: :flush, cards: [1, value4, value3, value2, value1]}
  end

  # Match all other flushes
  defp compute_score([%Card{value: val1, suit: suit}, %Card{value: val2, suit: suit}, 
                     %Card{value: val3, suit: suit}, %Card{value: val4, suit: suit}, 
                     %Card{value: highest, suit: suit}]) do
    %HandRank{type: :flush, cards: [highest, val4, val3, val2, val1]}
  end

  # Match an ace high card
  defp compute_score([%Card{value: 1}, %Card{value: second}, %Card{value: third},
                     %Card{value: fourth}, %Card{value: fifth}])
       when ((second != 1) and
             (second != third) and
             (third != fourth) and
             (fourth != fifth)
       ), 
       do: %HandRank{type: :high_card, cards: [1, fifth, fourth, third, second]}

  # Match any other high card
  defp compute_score([%Card{value: first}, %Card{value: second}, %Card{value: third},
                     %Card{value: fourth}, %Card{value: fifth}])
       when ((first != second) and
             (second != third) and
             (third != fourth) and
             (fourth != fifth)
       ), 
       do: %HandRank{type: :high_card, cards: [fifth, fourth, third, second, first]}

  # Match pairs, three of a kinds and four of a kinds
  defp compute_score(cards) do
    cards
    |> Enum.group_by(&(&1.value)) # Group by value
    |> Enum.map(fn({value, cards}) ->
         {length(cards), value}
       end) # Count number of each card
    |> sort_cards
    |> detect_type
  end

  defp detect_type(sorted_cards) do
    largest_group 
      = sorted_cards
        |> Enum.group_by(&(&1))
        |> Enum.max_by(fn({_, v}) -> length(v) end)
        |> (fn({_, v}) -> length(v) end).()

    case largest_group do
      2 -> %HandRank{type: :pair, cards: sorted_cards}
      3 -> %HandRank{type: :three_of_a_kind, cards: sorted_cards}
      4 -> %HandRank{type: :four_of_a_kind, cards: sorted_cards}
    end
  end

  def sort_cards(counts_and_values) do
    counts_and_values
      |> Enum.sort(fn({count1, val1}, {count2, val2}) ->
          # If either count is above 1, prioritize it
          if count1 > 1 || count2 > 1 do
            count1 > count2
          else # Otherwise compare value
            # Boost aces
            if val1 == 1 do
              val1 = 14
            end
            if val2 == 1 do
              val2 = 14
            end
            val1 > val2
          end
        end)
      |> Enum.flat_map(fn({count, value}) -> 
           1..count |> Enum.reduce([], fn(_, acc) ->
             acc ++ [value]
           end)
         end)
  end

  defp flatten(groups) do
    Enum.flat_map(groups, fn({_type, scores}) -> 
      scores
    end)
  end

  defp sort_by_value(cards) do
    cards |> Enum.sort(&(&1.value < &2.value))
  end

  defp group_by_types(scores) do
    Enum.group_by(scores, &(&1.type))
  end

  defp rank_each_group_by_high_card(groups) do
    Enum.map(groups, fn({type, scores}) ->
      {type, do_rank_scores_by_high_card(scores)}
    end)
  end

  defp rank_groups_by_types(groups) do
    Enum.sort(groups, fn({type_a, _}, {type_b, _}) -> 
      get_rank_of(type_a) > get_rank_of(type_b)
    end)
  end

  defp do_rank_scores_by_high_card(scores) do
    Enum.sort_by(scores,
      fn(%HandRank{} = score) -> 
        score.cards |> Enum.map(fn(x) ->
          if x == 1 do
            14
          else
            x
          end
        end)
      end,
      fn(a, b) -> a > b end
    )
  end

  defp get_rank_of(type) do
    case Enum.find_index(@type_rankings, fn(x) -> x == type end) do
      nil  -> raise "Unkown score: #{type}"
      rank -> rank
    end
  end
end
