defmodule Saladin.Impls.ArbitratedScratchpadTest do
  use ExUnit.Case

  test "basic implementation test" do
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
end
