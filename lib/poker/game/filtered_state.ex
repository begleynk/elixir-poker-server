defmodule Poker.Game.FilteredState do
  defstruct [
    id: nil,
    players: nil,
    positions: nil,
    pocket_cards: nil,
    small_blind: nil,
    big_blind: nil,
    community_cards: nil,
    pot: 0,
    next_action: nil,
    hand_value: nil,
  ]
  alias Poker.Game

  def new(%Game.State{} = state) do
    %Game.FilteredState{} |> add_public_information(state)
  end

  defp add_public_information(filtered_state, state) do
    Enum.reduce(Game.VisibilityFilter.public_attributes, filtered_state, fn(attr, acc) ->
      Map.update(acc, attr, Map.get(state, attr), fn(_) -> Map.get(state, attr) end)
    end)
  end
end
