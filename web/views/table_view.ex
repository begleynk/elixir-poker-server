defmodule Poker.TableView do
  use Poker.Web, :view
  use JaSerializer.PhoenixView

  alias Poker.{Table}

  location "/api/tables/:id"
  attributes [:seats, :size]

  def seats(%Table{ seats: seats }, _conn) do
    seats 
    |> Map.to_list
    |> convert_keys_to_strings
    |> Enum.into(Map.new)
  end

  defp convert_keys_to_strings(seats) do
    Enum.map(seats, fn({seat_number, occupier}) ->
      {Integer.to_string(seat_number), occupier}
    end)
  end
end
