defmodule Saladin.Module.BasicTest do
  use ExUnit.Case
  doctest Saladin.Module

  defmodule BasicTestModule do
    use Saladin.Module

    def run(state) do
      wait(state)
      run(state)
    end
  end

  test "module sends :ready after reset" do
    clock_pid = self()
    {:ok, pid} = BasicTestModule.start_link(%{:clock => clock_pid})
    assert_receive {:ready, mod_pid}, 5_000
    assert pid == mod_pid
  end

  test "module progresses after receiving :tiktok" do
    clock_pid = self()
    {:ok, pid} = BasicTestModule.start_link(%{:clock => clock_pid})
    assert_receive {:ready, mod_pid}, 5_000
    send(pid, {:tiktok})
    assert_receive {:ready, mod_pid}, 5_000
  end

  test "module progresses in a loop" do
    clock_pid = self()
    {:ok, pid} = BasicTestModule.start_link(%{:clock => clock_pid})
    assert_receive {:ready, mod_pid}, 5_000
    send(pid, {:tiktok})
    assert_receive {:ready, mod_pid}, 5_000
    send(pid, {:tiktok})
    assert_receive {:ready, mod_pid}, 5_000
    send(pid, {:tiktok})
    assert_receive {:ready, mod_pid}, 5_000
  end
end
