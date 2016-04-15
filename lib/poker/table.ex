defmodule Poker.Table do
  defstruct id: nil, size: nil, seats: nil
  use GenServer

  alias Poker.{Table, Player, TableEvent}

  def start_link(id, size: size) do
    GenServer.start_link(__MODULE__, [id, size], [name: via_tuple(id)])
  end

  def init([id, size]) do
    player_pids = Map.new # Used to monitor sitting players
    table = %Table{size: size, id: id, seats: build_seats(size)}

    TableEvent.broadcast!(%TableEvent{
      type: :new_table,
      table_id: id,
      table: table
    })
    
    {:ok, {table, player_pids}}
  end

  def info(table) do
    GenServer.call(table, :info)
  end

  def sit(table, player: player, seat: seat) do
    GenServer.call(table, {:sit, player, seat})
  end

  def leave(table) do
    GenServer.call(table, :leave)
  end

  def handle_call(:info, _caller, {table, _pids} = state) do
    {:reply, table, state}
  end

  def handle_call(:leave, {player_pid,_}, state) do
    {:reply, :ok, do_remove_player(player_pid, state)}
  end

  def handle_call({:sit, player, seat}, {player_pid,_}, {table, pids} = state) do
    cond do
      table |> player_already_sitting?(player) ->
        {:reply, {:error, :already_at_table}, state}
      table |> seat_taken?(seat) ->
        {:reply, {:error, :seat_taken}, state}
      true ->
        new_pids  = monitor_player(pids, player, player_pid)
        new_table = do_seat_player(table, player, seat)

        TableEvent.broadcast!(%TableEvent{
          type: :player_joined_table,
          info: %{
            player: player
          },
          table: new_table,
          table_id: new_table.id,
        })

        {:reply, :ok, {new_table, new_pids}}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, do_remove_player(pid, state)}
  end

  defp player_already_sitting?(%Table{seats: seats}, player) do
    seats 
      |> Map.to_list
      |> Enum.any?(fn({_seat, occupier}) ->
           case occupier do
             %Player{id: id} -> id == player.id
                      :empty -> false
           end
         end)
  end

  defp seat_taken?(%Table{seats: seats}, seat) do
    seats[seat] !== :empty
  end

  defp monitor_player(pids, player, pid) do
    ref = Process.monitor(pid)
    pids |> Map.put(pid, {player.id, ref})
  end

  defp demonitor_player(pids, pid, monitor_ref) do
    Process.demonitor(monitor_ref)
    pids |> Map.delete(pid)
  end

  defp do_seat_player(%Table{seats: seats} = table, player, seat) do
    %Table{ table | 
      seats: Map.update!(seats, seat, fn(_) -> player end)
    }
  end

  defp do_remove_player(pid, {%Table{} = table, pids}) do
    {player_id, monitor_ref} = pids[pid]

    {_, player}
      = table.seats
      |> Map.to_list
      |> Enum.find(fn({_,p}) -> 
           case p do
             :empty -> false
                p   -> p.id == player_id
           end
      end)

    new_pids  = demonitor_player(pids, pid, monitor_ref)
    new_table = remove_player_from_table(table, player_id)

    TableEvent.broadcast!(%TableEvent{
      type: :player_left_table,
      info: %{
        player: player,
      },
      table: new_table,
      table_id: new_table.id,
    })

    {new_table, new_pids}
  end

  defp remove_player_from_table(%Table{seats: seats} = table, player_id) do
    %Table{ table |
      seats: seats
       |> Map.to_list
       |> Enum.map(fn({seat, p}) ->
            case p do
              :empty -> {seat, :empty}
              %Player{} -> 
                if p.id == player_id do
                  {seat, :empty}
                else
                  {seat, p}
                end
            end
          end)
       |> Enum.into(Map.new)
    }
  end

  defp build_seats(size) do
    1..size |> Enum.reduce(Map.new, fn(i, acc) ->
      acc |> Map.put(i, :empty)
    end)
  end

  defp via_tuple(id) do
    {:via, :gproc, {:n, :l, {:table, id}}}
  end

end

