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
          send(pid, {:read_done, addr, value, state.tick_number})
          state

        {:write, addr, value, pid, req_tick_number} when req_tick_number < tick_number ->
          # IO.puts("write: #{addr}:#{value} from #{req_tick_number} executed at #{tick_number}")
          :ets.insert(state.plm, {addr, value})
          state = wait(state)

          # IO.puts("read: returning to request register: #{addr}:#{value} at #{state.tick_number}")
          send(pid, {:write_done, addr, value, state.tick_number})
          state
      after
        0 -> state
      end

    state = wait(state)
    run(state)
  end
end
