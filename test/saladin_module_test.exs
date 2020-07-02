defmodule TestModule do
  use Saladin.Module

  @impl true
  def reset(_state) do
    IO.puts("SimpleModule reset")
  end

  @impl true
  def run(state) do
    # Non-blocking read of inputs
    receive do
      {:hello} -> IO.puts("TestModule received the hello")
    after
      0 -> :ok
    end

    # Wait for the next clock cycle
    wait(state)

    # Loop by calling yourself recursively or anything else you might want to do
    run(state)
  end
end

defmodule Saladin.Module.Test do
  use ExUnit.Case
  doctest Saladin.Module

  test "module sends :ready after reset" do
    clock_pid = self()
    {:ok, pid} = TestModule.start_link(%{:clock => clock_pid})
    assert_receive {:ready, mod_pid}, 5_000
    assert pid == mod_pid
  end

  test "module progresses after receiving :tiktok" do
    clock_pid = self()
    {:ok, pid} = TestModule.start_link(%{:clock => clock_pid})
    assert_receive {:ready, mod_pid}, 5_000
    send(pid, {:tiktok})
    assert_receive {:ready, mod_pid}, 5_000
  end
end
