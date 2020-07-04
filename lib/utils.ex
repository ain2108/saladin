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
end
