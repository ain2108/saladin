defmodule Saladin.Impls.ArbitratedScratchpadTest do
  use ExUnit.Case

  test "basic implementation test" do
    {:ok, clock_pid} = Saladin.Clock.start_link(%{})
    {:ok, module_pid} = Saladin.Impls.ArbitratedScratchpad.start_link(%{clock: clock_pid})

  end

end
