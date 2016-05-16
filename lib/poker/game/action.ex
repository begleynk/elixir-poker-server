defmodule Poker.Game.Action do
  defstruct id: "", type: nil, amount: nil

  alias Poker.Game.Action

  def new(type: type, amount: amount) do
    %Action{
      id: generate_id,
      type: type,
      amount: amount,
    }
  end

  def call(amount: amount) do
    Action.new(type: :call, amount: amount)
  end

  defp generate_id do
    "table_action_" <> (UUID.uuid4(:hex) |> String.slice(0, 8))
  end
end
