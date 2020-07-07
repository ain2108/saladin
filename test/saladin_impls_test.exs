defmodule Saladin.Impls.ArbitratedScratchpadTest do
  use ExUnit.Case

  test "basic scratchpad implementation test" do
    # for registration
    {:ok, clock_pid} = Saladin.Clock.start_link(%{})
    plm_config = %{nbanks: 1, bank_size: 516}

    {:ok, module_pid} =
      Saladin.Impls.ArbitratedScratchpad.start_link(%{clock: clock_pid, plm_config: plm_config})

    Saladin.Utils.wait_for_state(clock_pid, &MapSet.member?(&1[:modules], module_pid))

    # wait() in reset, Scratchpad check #0, no work
    send(module_pid, {:tick, 0})
    # Scratchpad check #1, no work
    send(module_pid, {:tick, 1})

    send(module_pid, {:write, 17, 13, self(), 1})
    # Scratchpad check #2, need to do write
    send(module_pid, {:tick, 2})
    # Scratchpad check #3, PLM write complete, send confirmation
    send(module_pid, {:tick, 3})

    send(module_pid, {:read, 17, self(), 3})
    # to consumer only visible on cycle #4
    assert_receive {:write_done, 17, 13, 3}

    # Scratchpad check #4, need to do read
    send(module_pid, {:tick, 4})
    # Scratchpad check #5, PLM read and send back
    send(module_pid, {:tick, 5})
    # to consumer only visible on cycle #6
    assert_receive {:read_done, 17, 13, 5}
  end

  defmodule BasicConsumerModule do
    use Saladin.Module

    def run(state) do
      test_server = state.test_server
      scratchpad_server = state.scratchpad_server
      req_start_tick_number = state.tick_number

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
    plm_config = %{nbanks: 1, bank_size: 512}

    {:ok, scratchpad_pid} =
      Saladin.Impls.ArbitratedScratchpad.start_link(%{clock: clock_pid, plm_config: plm_config})

    {:ok, tester_pid} =
      BasicConsumerModule.start_link(%{
        clock: clock_pid,
        scratchpad_server: scratchpad_pid,
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
