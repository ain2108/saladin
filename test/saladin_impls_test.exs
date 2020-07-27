defmodule Saladin.Impls.ArbitratedScratchpadTest do
  use ExUnit.Case

  defmodule BasicConsumerModule do
    use Saladin.Module

    def run(state) do
      test_server = state.test_server
      scratchpad_server = state.scratchpad_server
      req_start_tick_number = state.tick_number

      # Be very careful with state, must keep passing it forward
      state =
        receive do
          {:test_read, addr} ->
            {state, res} =
              Saladin.Impls.ScratchpadConsumerInterface.read(scratchpad_server, addr, state)

            send(test_server, {res, req_start_tick_number})
            state

          {:test_write, addr, value} ->
            {state, res} =
              Saladin.Impls.ScratchpadConsumerInterface.write(
                scratchpad_server,
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

    {:ok, scratchpad_clock, scratchpad_input} =
      Saladin.Impls.ArbitratedScratchpad.start_link(%{clock: clock_pid, plm_config: plm_config})

    # Start the scratchpad consumer
    {:ok, tester_pid, _} =
      BasicConsumerModule.start_link(%{
        clock: clock_pid,
        # Notice how we pass the input pid as opposed to clock pid
        scratchpad_server: scratchpad_input,
        test_server: self()
      })

    Saladin.Utils.wait_for_state(
      clock_pid,
      &MapSet.equal?(&1[:modules], MapSet.new([tester_pid, scratchpad_clock]))
    )

    Saladin.Clock.start_clock(clock_pid)

    # assert false

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
      assert req_start_tick + Saladin.Impls.ScratchpadConsumerInterface.min_op_latency() ==
               req_done_tick + 1

      send(tester_pid, {:test_read, test_addr})
      assert_receive {{:read_done, read_addr, read_value, req_done_tick}, req_start_tick}

      assert read_addr == addr
      assert read_value == value

      assert req_start_tick + Saladin.Impls.ScratchpadConsumerInterface.min_op_latency() ==
               req_done_tick + 1
    end
  end
end
