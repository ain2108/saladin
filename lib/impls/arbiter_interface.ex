defmodule Saladin.ArbiterInterface do
  @doc """
  Write to req_register             (0)
  -> drive PLM ports                (1)
  -> writeback to response_register (2)
  -> value available for use        (3)
  """
  @min_op_latency 3

  def min_op_latency, do: @min_op_latency

  defp wait_write(pid, state) do
    tick_number = state.tick_number

    receive do
      {:write_done, addr, value, req_tick_number} when req_tick_number <= tick_number ->
        {state, {:write_done, addr, value, req_tick_number}}
    after
      0 ->
        state = Saladin.Utils.wait(state)
        wait_write(pid, state)
    end
  end

  def write(pid, addr, value, state) do
    # Send the request
    Saladin.Module.Input.drive(pid, {:write, addr, value, state.input, state.tick_number})
    # Wait a clock cycle
    state = Saladin.Utils.wait(state)
    wait_write(pid, state)
  end

  defp wait_read(pid, state) do
    tick_number = state.tick_number

    receive do
      {:read_done, addr, value, req_tick_number} when req_tick_number <= tick_number ->
        {state, {:read_done, addr, value, req_tick_number}}
    after
      0 ->
        state = Saladin.Utils.wait(state)
        wait_read(pid, state)
    end
  end

  def read(pid, addr, state) do
    # Send the request, provide our own input port for response
    Saladin.Module.Input.drive(pid, {:read, addr, state.input, state.tick_number})
    # Wait a clock cycle
    state = Saladin.Utils.wait(state)
    wait_read(pid, state)
  end

  def register_consumer(scratchpad_pid, state) do
    send(scratchpad_pid, {:register_consumer, self(), state.input})

    receive do
      {:register_consumer_ok, scratchpad_input} -> scratchpad_input
    end
  end
end
