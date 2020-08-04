defmodule Saladin.SimpleArbiterRRTest do
  use ExUnit.Case

  defmodule BasicConsumerModule do
    use Saladin.Module

    def reset(state) do
      scratchpad_input = Saladin.ArbiterInterface.register_consumer(state.scratchpad_pid, state)

      state |> Map.put(:scratchpad_input, scratchpad_input)
    end

    def run(state) do
      test_server = state.test_server
      scratchpad_input = state.scratchpad_input
      req_start_tick_number = state.tick_number

      # Be very careful with state, must keep passing it forward
      state =
        receive do
          {:test_read, addr} ->
            {state, res} = Saladin.ArbiterInterface.read(scratchpad_input, addr, state)

            send(test_server, {res, req_start_tick_number})
            state

          {:test_write, addr, value} ->
            {state, res} =
              Saladin.ArbiterInterface.write(
                scratchpad_input,
                addr,
                value,
                state
              )

            send(test_server, {res, req_start_tick_number})
            state
        end

      state = wait(state)
      run(state)
    end
  end

  test "basic scratchpad interface test" do
    bank_size = 512
    max_value = 65536
    {:ok, clock_pid} = Saladin.Clock.start_link(%{})

    # Initialize the ScratchPad
    plm_config = %{nbanks: 1, bank_size: 512}

    {:ok, scratchpad_pid, _} =
      Saladin.SimpleArbiterRR.start_link(%{
        clock: clock_pid,
        plm_config: plm_config,
        num_consumers: 1
      })

    # Start the scratchpad consumer
    {:ok, tester_pid, _} =
      BasicConsumerModule.start_link(%{
        clock: clock_pid,
        # Notice how we pass the input pid as opposed to clock pid
        scratchpad_pid: scratchpad_pid,
        test_server: self()
      })

    Saladin.Utils.wait_for_state(
      clock_pid,
      &MapSet.equal?(&1[:modules], MapSet.new([tester_pid, scratchpad_pid]))
    )

    Saladin.Clock.start_clock(clock_pid)

    for test_addr <- 0..(bank_size - 1) do
      test_value = :rand.uniform(max_value)
      send(tester_pid, {:test_write, test_addr, test_value})
      assert_receive {{:write_done, addr, value, req_done_tick}, req_start_tick}

      assert test_addr == addr
      assert test_value == value

      # Want to make sure the request takes the right number of cycles
      # Req_done_tick marks the clock cycle when the value was written in response register.module()
      # min_op_latency measures the period until the value is available to the consumer.module
      # Since there is a single consumer,
      assert req_start_tick + Saladin.ArbiterInterface.min_op_latency() ==
               req_done_tick

      send(tester_pid, {:test_read, test_addr})
      assert_receive {{:read_done, read_addr, read_value, req_done_tick}, req_start_tick}

      assert read_addr == addr
      assert read_value == value

      assert req_start_tick + Saladin.ArbiterInterface.min_op_latency() ==
               req_done_tick
    end
  end
end

defmodule BasicConsumerModule do
  use Saladin.Module
  use ExUnit.Case

  def reset(state) do
    scratchpad_input = Saladin.ArbiterInterface.register_consumer(state.scratchpad_pid, state)

    state
    |> Map.put(:scratchpad_input, scratchpad_input)
    |> Map.put(:cur_addr, state.consumer_id)
  end

  defp do_work(state, cur_work_cycle, total_work_cycles)
       when cur_work_cycle >= total_work_cycles do
    state
  end

  defp do_work(state, cur_work_cycle, total_work_cycles)
       when cur_work_cycle < total_work_cycles do
    state = wait(state)
    do_work(state, cur_work_cycle + 1, total_work_cycles)
  end

  defp spin(state) do
    wait(state) |> spin()
  end

  def run(state) do
    tester_pid = state.tester_pid
    scratchpad_input = state.scratchpad_input
    addr = state.cur_addr
    total_consumers = state.total_consumers
    work_cycles = state.work_cycles

    # Read the value
    read_start_tick = state.tick_number
    {state, _} = Saladin.ArbiterInterface.read(scratchpad_input, addr, state)

    assert state.tick_number >=
             read_start_tick + Saladin.ArbiterInterface.min_op_latency()

    # Simulate work for # work cycles
    work_start_tick = state.tick_number
    state = do_work(state, 0, work_cycles)
    assert state.tick_number == work_start_tick + work_cycles

    # Continue work if needed
    if addr + total_consumers < state.total_work do
      state = Map.update!(state, :cur_addr, &(&1 + total_consumers))
      run(state)
    else
      # IO.puts(:stderr, "consumer #{state.consumer_id} sending to tester")
      send(tester_pid, {:consumer_done, state.consumer_id, state.tick_number})
      # IO.puts(:stderr, "consumer #{state.consumer_id} entering spin")
      spin(state)
    end
  end
end
