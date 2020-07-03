defmodule Saladin.Clock do
  def start_link(state) do
    # Want to make sure our simulation crashes in case a process crashes
    Task.start_link(fn -> init(state) end)
  end

  defp init(state) do
    # TODO: Initialize the state
    state = state |> Map.put(:modules, MapSet.new()) |> Map.put(:running, false)
    loop(state)
  end

  defp handle_ready(pid, state) do
    # Check if pid registered with clock
    state
  end

  defp clock_tick(state) do
    state
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
          Map.update(state, :modules, MapSet.new(), &(&1 |> MapSet.put(pid)))

        {:state, pid} ->
          send(pid, {:ok, state})
          state
      end

    state = clock_tick(state)

    loop(state)
  end
end
