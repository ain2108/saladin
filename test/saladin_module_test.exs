defmodule Saladin.Module.Test do
  use ExUnit.Case
  doctest Saladin.Module

  test "mod sends :ready after reset" do
    clock_pid = self()
    {:ok, pid} = Saladin.Module.start_link(%{:clock => clock_pid})
    assert_receive {:ready, mod_pid}, 5_000
    assert pid == mod_pid
  end
end
