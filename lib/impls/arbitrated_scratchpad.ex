defmodule Saladin.Impls.ArbitratedScratchpad do
  use Saladin.Module

  def reset(state) do
    plm = :ets.new(:buckets_registry, [:set, :private])

    # Initialize the PLM
    for addr <- 0..(state.plm_config.nbanks * state.plm_config.bank_size - 1),
        do: :ets.insert(plm, {addr, 0})

    state |> Map.put(:plm, plm)
  end

  def run(state) do
    # Check if there is a
    # uncommenting this removes the dyalizer error
    tick_number = state.tick_number

    # IO.puts("#{tick_number}")

    # We want to read the request sent on previous clock cycle
    state =
      receive do
        {:read, addr, pid, req_tick_number} when req_tick_number < tick_number ->
          [{_, value}] = :ets.lookup(state.plm, addr)
          # IO.puts("read: #{addr}:#{value} from #{req_tick_number} executed at #{tick_number}")
          # clock cycle to read from PLM
          state = wait(state)
          # IO.puts("read: to request register: #{addr}:#{value} at #{state.tick_number}")
          # TODO: Might wanna send the state.tick_number + 1, i.e the tick when the value is actually available.
          Saladin.Module.Input.drive(pid, {:read_done, addr, value, state.tick_number})
          state

        {:write, addr, value, pid, req_tick_number} when req_tick_number < tick_number ->
          # IO.puts("write: #{addr}:#{value} from #{req_tick_number} executed at #{tick_number}")
          :ets.insert(state.plm, {addr, value})
          state = wait(state)

          # IO.puts("write: returning to request register: #{addr}:#{value} at #{state.tick_number}")
          Saladin.Module.Input.drive(pid, {:write_done, addr, value, state.tick_number})
          state
      after
        0 -> state
      end

    state = wait(state)
    run(state)
  end
end

defmodule Saladin.Impls.ScratchpadConsumerInterface do
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
      {:write_done, addr, value, req_tick_number} when req_tick_number < tick_number ->
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
      {:read_done, addr, value, req_tick_number} when req_tick_number < tick_number ->
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
end
