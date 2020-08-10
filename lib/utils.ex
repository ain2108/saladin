defmodule Saladin.Utils do
  @spec get_state(atom | pid | port | {atom, atom}) :: any
  def get_state(pid) do
    send(pid, {:state, self()})

    receive do
      {:state, state} -> state
    end
  end

  @spec wait_for_state(atom | pid | port | {atom, atom}, (any -> any), any) :: nil
  def wait_for_state(clock_pid, conditional, backoff \\ 10) do
    state = get_state(clock_pid)

    unless conditional.(state) do
      Process.sleep(backoff)
      wait_for_state(clock_pid, conditional)
    end
  end

  defp report_state(state) do
    # Check inbox for :state msgs and drain it
    receive do
      {:state, pid} ->
        send(pid, {:state, state})
        report_state(state)
    after
      0 -> :ok
    end
  end

  defp drain_input(input) do
    # The goal of the function is to drain the input queue, and send the messages in the input queue to self for processing.

    # Read the input queue fully
    input_msgs = Saladin.Module.Input.read_all(input)

    # For each msg in the input queue, send it to the main process
    for msg <- input_msgs do
      send(self(), msg)
    end

    # After all messages are sent, send the :drain_done.
    # Beam guarantees us order for messages sent between two processes.
    send(self(), :drain_done)

    # Block until :drain_done message is recived, thus guaranteeing that the real messages are sitting in process queue.
    receive do
      :drain_done -> :ok
    end
  end

  def wait(state, timeout \\ 10_000) do
    # Check if anyone wants to see the state
    report_state(state)

    res = Saladin.Clock.tick(state.clock, timeout)

    case res do
      {:ok, tick_number} ->
        :ok = drain_input(state.input)
        %{state | tick_number: tick_number}

      {:terminate} ->
        GenServer.stop(state.input)
        exit(:normal)
    end
  end

  def terminate(pid) do
    send(pid, {:terminate})
  end
end
