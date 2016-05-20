defmodule Poker.Game.NextAction do
  defstruct type: "", to_call: nil, actions: [], player: nil

  def new do
    %Poker.Game.NextAction{}
  end
end
