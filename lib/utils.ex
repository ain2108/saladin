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

  def wait(state, timeout \\ 10_000) do
    # Check if anyone wants to see the state
    report_state(state)

    {:ok, tick_number} = Saladin.Clock.tick(state.clock, timeout)
    %{state | tick_number: tick_number}
  end
end
