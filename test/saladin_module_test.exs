defmodule Saladin.Module.BasicTest do
  use ExUnit.Case
  doctest Saladin.Module

  defmodule BasicTestModule do
    use Saladin.Module

    def run(state) do
      state = wait(state)
      run(state)
    end
  end

  test "module attempts registration with clock" do
    {:ok, pid, _} = BasicTestModule.start_link(%{:clock => self()})
    assert_receive {:register, mod_pid}, 5_000
    assert pid == mod_pid
  end

  test "module sends :ready after reset" do
    {:ok, pid, _} = BasicTestModule.start_link(%{:clock => self()})
    send(pid, {:registration_ok})
    assert_receive {:ready, mod_pid}, 5_000
    assert pid == mod_pid
  end

  test "module progresses after receiving :tick" do
    {:ok, pid, _} = BasicTestModule.start_link(%{:clock => self()})
    send(pid, {:registration_ok})
    assert_receive {:ready, mod_pid}, 5_000
    send(pid, {:tick, 0})
    assert_receive {:ready, mod_pid}, 5_000
  end

  test "module progresses for many ticks" do
    {:ok, pid, _} = BasicTestModule.start_link(%{:clock => self()})
    send(pid, {:registration_ok})
    assert_receive {:ready, mod_pid}, 5_000
    send(pid, {:tick, 0})
    assert_receive {:ready, mod_pid}, 5_000
    send(pid, {:tick, 1})
    assert_receive {:ready, mod_pid}, 5_000
    send(pid, {:tick, 2})
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
      state = wait(state)
      run(state)
    end
  end

  test "module with custom reset override" do
    {:ok, pid, _} = BasicTestModuleWithReset.start_link(%{:clock => self(), reset_serv: self()})
    send(pid, {:registration_ok})
    assert_receive {:reset_done, mod_pid, state}, 5_000
    %{test_value: test_value} = state

    assert test_value == 0

    # %{test_value: value} = Saladin.Utils.get_state(pid) #TODO: Needs more thought
  end
end

defmodule Saladin.Module.Input.BasicTest do
  use ExUnit.Case
  doctest Saladin.Module.Input

  test "test basic behaviour of the port" do
    {:ok, pid} = Saladin.Module.Input.start_link([])
    total_writes = 5

    for i <- 0..total_writes do
      Saladin.Module.Input.drive(pid, {:some, i})
    end

    res = Saladin.Module.Input.read_all(pid)

    inspect(res)

    assert length(res) == total_writes + 1

    res
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.each(fn {msg, i} -> assert msg == {:some, i} end)
  end
end
