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
      seats: build_seats(size, id)
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

  def seat(table, seat) do
    GenServer.call(table, {:seat, seat})
  end

  def handle_call(:info, _caller, {table, _pids} = state) do
    {:reply, table, state}
  end

  def handle_call({:seat, seat}, _caller, {table, _pids} = state) do
    {:reply, table.seats |> Enum.at(seat), state}
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
    Enum.any?(seats, fn(%{ player: p }) ->
      case p do
        %Player{id: id} -> id == player.id
                    nil -> false
      end
    end)
  end

  defp enough_players_sitting(table) do
    player_count(table) > 1
  end

  defp player_count(table) do
    Enum.count(table.seats, fn(seat) ->
      seat.status !== :empty
    end)
  end

  defp sitting_players(table) do
    table.seats
    |> Enum.filter(fn(seat) -> seat.status != :empty end)
    |> Enum.map(fn(seat) -> seat.player.id end)
  end

  defp seat_taken?(%Table{seats: seats}, position) do
    status = 
      seats 
      |> seat_in_position(position)
      |> Map.fetch!(:status) 
    
    status !== :empty
  end

  defp seat_in_position(seats, position) do
    Enum.find(seats, fn(%{position: pos}) ->
      position == pos
    end)
  end

  defp monitor_player(pids, player, pid) do
    ref = Process.monitor(pid)
    pids |> Map.put(pid, {player.id, ref})
  end

  defp demonitor_player(pids, pid, monitor_ref) do
    Process.demonitor(monitor_ref)
    pids |> Map.delete(pid)
  end

  defp do_seat_player(%Table{seats: seats} = table, player, position) do
    %Table{ table | 
      seats: Enum.map(seats, fn(seat) ->
        if seat.position == position do
          seat
          |> Map.put(:player, player)
          |> Map.put(:status, :playing)
        else
          seat
        end
      end)
    }
  end

  defp do_remove_player(pid, {%Table{} = table, pids}) do
    {player_id, monitor_ref} = pids[pid]

    new_pids  = demonitor_player(pids, pid, monitor_ref)
    new_table = remove_player_from_table(table, player_id)

    Table.EventBroker.broadcast!(%Table.Event{
      type: :player_left_table,
      info: %{
        player: %Player{ id: player_id },
      },
      table: new_table,
      table_id: new_table.id,
    })

    {new_table, new_pids}
  end

  defp remove_player_from_table(%Table{seats: seats} = table, player_id) do
    %Table{ table |
      seats: Enum.map(seats, fn(seat) ->
        case seat.player do
          %Player{ id: ^player_id } -> %{seat | player: nil, status: :empty}
          %Player{} -> seat
                nil -> seat
        end
      end)
    }
  end

  defp build_seats(size, table_id) do
    0..(size - 1) |> Enum.reduce([], fn(i, acc) ->
      [%{ status: :empty, player: nil, id: i, position: i, table: table_id } | acc]
    end) |> Enum.reverse
  end

  defp via_tuple(id) do
    {:via, :gproc, {:n, :l, {:table, id}}}
  end
end
