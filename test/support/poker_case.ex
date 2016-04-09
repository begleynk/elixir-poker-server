defmodule Poker.PokerCase do
  use ExUnit.CaseTemplate

  setup do
    on_exit fn ->
      # Kill all table processes
      sup = Process.whereis(Poker.TableSupervisor)
      sup
        |> Supervisor.which_children
        |> Enum.map(fn({_, pid, _, _}) ->
             Supervisor.terminate_child(sup, pid)
           end)
      
      # Clear lobby of all tables
      :ok = Poker.Lobby.clear
    end
    :ok
  end
end
