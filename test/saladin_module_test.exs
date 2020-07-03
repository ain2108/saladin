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

  test "module attempts registration with clock" do
    {:ok, pid} = BasicTestModule.start_link(%{:clock => self()})
    assert_receive {:register, mod_pid}, 5_000
    assert pid == mod_pid
  end

  test "module sends :ready after reset" do
    {:ok, pid} = BasicTestModule.start_link(%{:clock => self()})
    send(pid, {:registration_ok})
    assert_receive {:ready, mod_pid}, 5_000
    assert pid == mod_pid
  end

  test "module progresses after receiving :tiktok" do
    {:ok, pid} = BasicTestModule.start_link(%{:clock => self()})
    send(pid, {:registration_ok})
    assert_receive {:ready, mod_pid}, 5_000
    send(pid, {:tick})
    assert_receive {:ready, mod_pid}, 5_000
  end

  test "module progresses in a loop" do
    {:ok, pid} = BasicTestModule.start_link(%{:clock => self()})
    send(pid, {:registration_ok})
    assert_receive {:ready, mod_pid}, 5_000
    send(pid, {:tick})
    assert_receive {:ready, mod_pid}, 5_000
    send(pid, {:tick})
    assert_receive {:ready, mod_pid}, 5_000
    send(pid, {:tick})
    assert_receive {:ready, mod_pid}, 5_000
  end
end
