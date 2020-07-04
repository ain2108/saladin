defmodule Saladin.Clock do
  @spec start_link(any) :: {:ok, pid}
  def start_link(state) do
    Task.start_link(fn -> init(state) end)
  end

  @spec start(any) :: {:ok, pid}
  def start(state) do
    Task.start(fn -> init(state) end)
  end

  @spec start_clock(atom | pid | port | {atom, atom}) :: any
  def start_clock(clock) do
    send(clock, {:start})
  end

  @spec stop_clock(atom | pid | port | {atom, atom}) :: any
  def stop_clock(clock) do
    send(clock, {:stop})
  end

  defp init(state) do
    # TODO: Initialize the state
    state =
      state
      |> Map.put(:modules, MapSet.new())
      |> Map.put(:running, false)
      |> Map.put(:ready_count, 0)
      |> Map.put(:tick_count, 0)

    loop(state)
  end

  defp handle_ready(_pid, state) do
    # Bump the count
    Map.update!(state, :ready_count, &(&1 + 1))
  end

  defp clock_tick(state) do
    case state do
      %{running: running} when running == false ->
        state

      %{modules: modules, ready_count: ready_count, running: running} when running == true ->
        # If we received all the ready signals, the ready_count should be equat to size of the modules
        if ready_count == MapSet.size(modules) do
          Enum.each(modules, fn pid -> send(pid, {:tick}) end)
          %{state | ready_count: 0} |> Map.update!(:tick_count, &(&1 + 1))
        else
          state
        end
    end
  end

  defp loop(state) do
    state =
      receive do
        # Sent by Saladin.Modules on wait
        {:ready, pid} ->
          handle_ready(pid, state)

        {:start} ->
          %{state | running: true}

        {:stop} ->
          %{state | running: false}

        {:register, pid} ->
          send(pid, {:registration_ok})
          Map.update!(state, :modules, &(&1 |> MapSet.put(pid)))

        {:state, pid} ->
          send(pid, {:state, state})
          state

        msg ->
          Process.exit(self(), "unknown message: #{Enum.join(Tuple.to_list(msg))}")
      end

    state = clock_tick(state)

    loop(state)
  end
end
