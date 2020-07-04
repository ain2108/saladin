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

  test "module progresses after receiving :tick" do
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

  defmodule BasicTestModuleWithReset do
    use Saladin.Module

    def reset(state) do
      state = state |> Map.put(:test_value, 0)
      send(state.reset_serv, {:reset_done, self(), state})
      state
    end

    def run(state) do
      wait(state)
      run(state)
    end
  end

  test "module with custom reset override" do
    {:ok, pid} = BasicTestModuleWithReset.start_link(%{:clock => self(), reset_serv: self()})
    send(pid, {:registration_ok})
    assert_receive {:reset_done, mod_pid, state}, 5_000
    %{test_value: test_value} = state

    assert test_value == 0

    # %{test_value: value} = Saladin.Utils.get_state(pid) #TODO: Needs more thought
  end

  test "module resets on :reset" do
    {:ok, pid} = BasicTestModuleWithReset.start_link(%{:clock => self(), reset_serv: self()})
    send(pid, {:registration_ok})
    assert_receive {:reset_done, mod_pid, state}, 5_000

    # Send the next reset to be executed on the next clock cycle
    send(pid, {:reset})
    send(pid, {:tick})

    assert_receive {:reset_done, mod_pid, state}, 5_000
  end
end
