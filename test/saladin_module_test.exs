defmodule TestModule do
  use Saladin.Module

  @impl true
  def reset(state) do
    IO.puts("SimpleModule reset")
  end

  @impl true
  def loop(state) do
    # Main compute loop

    # Block on
    receive do
      {:hello} -> IO.puts("TestModule received the hello")
    after
      0 -> :ok
    end

    # Wait for the next clock cycle
    Saladin.Module.wait(state)

    # Get back into the loop
    loop(state)
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

  # test "module progresses after receiving :tiktok" do
  #   clock_pid = self()
  #   {:ok, pid} = Saladin.Module.start_link(%{:clock => clock_pid})
  #   assert_receive {:ready, mod_pid}, 5_000
  #   send pid, {:tiktok}
  #   assert_receive {:ready, mod_pid}, 5_000
  # end
end
