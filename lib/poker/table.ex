defmodule Poker.Table do
  defstruct id: nil, size: nil, seats: nil
  use GenServer

  alias Poker.{Table}

  def start_link(id, {:size, size}) do
    GenServer.start_link(__MODULE__, [id, size], [])
  end

  def init([id, size]) do
    {:ok, %Table{size: size, id: id, seats: build_seats(size)}}
  end

  def info(table) do
    GenServer.call(table, :info)
  end

  def handle_call(:info, _caller, state) do
    {:reply, state, state}
  end

  defp build_seats(size) do
    1..size |> Enum.reduce(Map.new, fn(i, acc) ->
      acc |> Map.put(i, :empty)
    end)
  end
end
