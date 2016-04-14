defmodule Poker.PokerCase do
  use ExUnit.CaseTemplate

  setup do
    sup = Process.whereis(Poker.TableSupervisor)
    sup
      |> Supervisor.which_children
      |> Enum.map(fn({_, pid, _, _}) ->
           Supervisor.terminate_child(sup, pid)
         end)
    :ok = Poker.Lobby.clear
    
    :ok
  end
end
