defmodule Saladin.Impls.ArbitratedScratchpadTest do
  use ExUnit.Case

  test "basic implementation test" do
    {:ok, clock_pid} = Saladin.Clock.start_link(%{})
    {:ok, module_pid} = Saladin.Impls.ArbitratedScratchpad.start_link(%{clock: clock_pid})
    Saladin.Utils.wait_for_state(clock_pid, &MapSet.member?(&1[:modules], module_pid))
  end
end
