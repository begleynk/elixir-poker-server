defmodule Poker.Game.Winner do
  alias Poker.Game

  def determine(%Game.State{ phase: :showdown } = state) do
    state.players
    |> determine_ranks(state.community_cards, state.pocket_cards)
    |> order_by_card_ranks
    |> Enum.fetch!(0)
    |> (fn({id, _}) -> id end).()
  end

  defp order_by_card_ranks(players_and_card_ranks) do
    Enum.sort(players_and_card_ranks, fn({_, rank1}, {_, rank2}) ->
      Poker.HandRank.compare([rank1, rank2]) == [rank1, rank2]
    end)
  end

  defp determine_ranks(players, community_cards, pocket_cards) do
    Enum.map(players, fn(p) -> 
      {pc1, pc2} = pocket_cards[p]
      {p, Poker.HandRank.determine_best_hand(community_cards ++ [pc1, pc2])}
    end)
  end
end
