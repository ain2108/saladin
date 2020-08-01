defmodule Saladin.SimpleArbiterRR do
  use Saladin.Module

  defp wait_consumer_registration(state, cur, num_consumers) do
    # Register consumers
    if cur < num_consumers do
      receive do
        {:register_consumer, consumer_pid, consumer_input} ->
          send(consumer_pid, {:register_consumer_ok, state.input})

          # Add the consumer_pid to the array of consumers
          Map.update!(state, :consumers, &(&1 |> Map.put(cur, consumer_input)))
          |> wait_consumer_registration(cur + 1, num_consumers)
      after
        5_000 ->
          Process.exit(
            self(),
            "Missing consumer registration. Make sure all scratchpad consumers send :register_consumer"
          )
      end
    else
      state
    end
  end

  def reset(state) do
    plm = :ets.new(:buckets_registry, [:set, :private])

    plm_init = Map.get(state.plm_config, :plm_init, [])

    # Initialize the PLM
    for addr <- 0..(state.plm_config.nbanks * state.plm_config.bank_size - 1),
        do: :ets.insert(plm, {addr, 0})

    # Update PLM with init values
    for addr_value <- plm_init do
      :ets.insert(plm, addr_value)
    end

    # Wait for all consumers to register
    state = state |> Map.put(:consumers, %{}) |> Map.put(:plm, plm) |> Map.put(:cur_consumer_i, 0)
    wait_consumer_registration(state, 0, state.num_consumers)
  end

  def run(state) do
    # Check if there is a
    tick_number = state.tick_number
    cur_consumer = state.consumers[state.cur_consumer_i]

    # We want to read the request sent on previous clock cycle
    state =
      receive do
        # Notice the strict <, req_tick_number is the cycle on which the consumer was driving register inputs
        # req_tick_number + 1 is the earliest cycle when request register value is available to the arbitrator
        {:read, addr, pid, req_tick_number}
        when req_tick_number < tick_number and pid == cur_consumer ->
          # clock cycle to read from PLM
          state = wait(state)
          [{_, value}] = :ets.lookup(state.plm, addr)

          # Produce the output, only should become visible to consumer next clock cycle
          Saladin.Module.Input.drive(pid, {:read_done, addr, value, state.tick_number + 1})
          # clock cycle spent writing into output register
          state = wait(state)

          # Output signal driven by the output register
          state

        {:write, addr, value, pid, req_tick_number}
        when req_tick_number < tick_number and pid == cur_consumer ->
          # IO.puts("write: #{addr}:#{value} from #{req_tick_number} executed at #{tick_number}")
          :ets.insert(state.plm, {addr, value})
          state = wait(state)

          # Produce the output, only should become visible to consumer next clock cycle
          Saladin.Module.Input.drive(pid, {:write_done, addr, value, state.tick_number + 1})
          # clock cycle spent writing into output register
          state = wait(state)

          # IO.puts("write: returning to request register: #{addr}:#{value} at #{state.tick_number}")
          state
      after
        # If no valid request, need to wait a clock cycle anyways
        0 -> wait(state)
      end

    state |> Map.update!(:cur_consumer_i, &rem(&1 + 1, state.num_consumers)) |> run()
  end
end
