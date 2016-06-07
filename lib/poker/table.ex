defmodule Poker.Table do
  defstruct id: nil, size: nil, seats: nil, blinds: nil, current_game: nil
  use GenServer

  alias Poker.{Table, Player, GameSupervisor}

  def start_link(id: id, size: size, blinds: blinds) do
    GenServer.start_link(__MODULE__, [id, size, blinds], [name: via_tuple(id)])
  end

  def init([id, size, blinds]) do
    player_pids = Map.new # Used to monitor sitting players
    table = %Table{
      id: id, 
      size: size, 
      blinds: blinds, 
      seats: build_seats(size)
    }

    Table.EventBroker.broadcast!(%Table.Event{
      type: :new_table,
      table_id: id,
      table: table
    })
    
    {:ok, {table, player_pids}}
  end

  def whereis(table_id) do
    :gproc.whereis_name({:n, :l, {:table, table_id}})
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

  def current_game(table) do
    GenServer.call(table, :current_game)
  end

  def handle_call(:info, _caller, {table, _pids} = state) do
    {:reply, table, state}
  end

  def handle_call(:current_game, _caller, {table, _pids} = state) do
    {:reply, table.current_game, state}
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

        Table.EventBroker.broadcast!(%Table.Event{
          type: :player_joined_table,
          info: %{
            player: player
          },
          table: new_table,
          table_id: new_table.id,
        })

        GenServer.cast(self, :maybe_start_new_game)

        {:reply, :ok, {new_table, new_pids}}
    end
  end

  def handle_cast(:maybe_start_new_game, {table, pids} = state) do
    if enough_players_sitting(table) do
      {:ok, game_pid} = GameSupervisor.start_child(
        players: sitting_players(table), 
        blinds: table.blinds
      )
      {:noreply, {%Table{table | current_game: game_pid}, pids}}
    else
      {:noreply, state}
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

  defp enough_players_sitting(table) do
    player_count(table) > 1
  end

  defp player_count(table) do
    table.seats
    |> Map.to_list
    |> Enum.filter(fn({_, player}) -> player != :empty end)
    |> length
  end

  defp sitting_players(table) do
    table.seats
    |> Map.to_list
    |> Enum.filter(fn({_, player}) -> player != :empty end)
    |> Enum.map(fn({_, player}) -> player end)
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

    Table.EventBroker.broadcast!(%Table.Event{
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
