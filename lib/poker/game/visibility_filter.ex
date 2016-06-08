defmodule Poker.Game.VisibilityFilter do
  alias Poker.Game

  @public_attributes [
    :id, 
    :big_blind, 
    :small_blind, 
    :players, 
    :positions,
    :community_cards,
    :pot,
    :next_action,
  ]

  def filter_state(%Game.State{} = state, :admin) do
    state
  end

  def filter_state(%Game.State{} = state, player_id) do
    Game.FilteredState.new(state)
    |> add_pocket_cards(state, player_id)
    |> add_hand_values(state, player_id)
  end

  def public_attributes do
    @public_attributes
  end

  defp add_pocket_cards(filtered_state, state, player_id) do
    %Game.FilteredState{ filtered_state | 
      pocket_cards: state.pocket_cards[player_id]
    }
  end

  defp add_hand_values(filtered_state, %Game.State{ phase: :showdown } = state, player_id) do
    %Game.FilteredState{ filtered_state | 
      hand_value: state.hand_values[player_id],
      positions: reveal_hands(state)
    }
  end

  defp add_hand_values(filtered_state, state, player_id) do
    %Game.FilteredState{ filtered_state | 
      hand_value: state.hand_values[player_id]
    }
  end

  defp reveal_hands(state) do
    Enum.map(state.positions, fn({pos, id, status}) ->
      {pos, id, status, state.pocket_cards[id], state.hand_values[id]}
    end)
  end
end
