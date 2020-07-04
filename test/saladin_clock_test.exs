defmodule Saladin.Clock.BasicTest do
  use ExUnit.Case
  doctest Saladin.Clock

  test "registration with clock module successful" do
    {:ok, pid} = Saladin.Clock.start_link(%{})
    send(pid, {:register, self()})
    assert_receive {:registration_ok}, 500
  end

  test "clock module returns state when asked" do
    {:ok, pid} = Saladin.Clock.start_link(%{})
    send(pid, {:register, self()})
    send(pid, {:state, self()})
    assert_receive {:state, state}, 500
    %{modules: modules, running: running} = state
    assert running == false
    assert MapSet.member?(modules, self())
  end

  test "clock module starts and stops running on :start and :stop" do
    {:ok, pid} = Saladin.Clock.start_link(%{})

    send(pid, {:start})
    send(pid, {:state, self()})
    assert_receive {:state, state}, 500
    %{modules: _, running: running} = state
    assert running == true

    send(pid, {:stop})
    send(pid, {:state, self()})
    assert_receive {:state, state}, 500
    %{modules: _, running: running} = state
    assert running == false
  end

  test "clock crashes on unknown message" do
    {:ok, pid} = Saladin.Clock.start(%{})
    ref = Process.monitor(pid)
    send(pid, {:die})
    assert_receive {:DOWN, ^ref, _, _, _}, 500
  end
end

defmodule Saladin.Clock.ModuleIntegrationTest do
  use ExUnit.Case
  doctest Saladin.Clock

  defmodule BasicTestModule do
    use Saladin.Module

    def run(state) do
      send(state[:hello], {:hello})
      wait(state)
      run(state)
    end
  end

  # Blocks infinitely if registatrion never occurs
  def wait_for_state(clock_pid, conditional, backoff \\ 10) do
    send(clock_pid, {:state, self()})

    state =
      receive do
        {:state, state} -> state
      end

    unless conditional.(state) do
      Process.sleep(backoff)
      wait_for_state(clock_pid, conditional)
    end
  end

  def get_state(pid) do
    send(pid, {:state, self()})

    receive do
      {:state, state} -> state
    end
  end

  test "module registers with the clock correctly" do
    {:ok, clock_pid} = Saladin.Clock.start_link(%{})
    {:ok, module_pid} = BasicTestModule.start_link(%{clock: clock_pid})
    wait_for_state(clock_pid, &MapSet.member?(&1[:modules], module_pid))
  end

  test "clock sends ticks to the module" do
    {:ok, clock_pid} = Saladin.Clock.start_link(%{})
    {:ok, module_pid} = BasicTestModule.start_link(%{clock: clock_pid, hello: self()})
    wait_for_state(clock_pid, &MapSet.member?(&1[:modules], module_pid))
    Saladin.Clock.start_clock(clock_pid)
    assert_receive {:hello}
  end

  test "clock ticks the module 1000 times" do
    {:ok, clock_pid} = Saladin.Clock.start_link(%{})
    {:ok, module_pid} = BasicTestModule.start_link(%{clock: clock_pid, hello: self()})
    wait_for_state(clock_pid, &MapSet.member?(&1[:modules], module_pid))
    Saladin.Clock.start_clock(clock_pid)
    for _ <- 0..1000, do: assert_receive({:hello})
    Saladin.Clock.stop_clock(clock_pid)

    %{tick_count: tick_count} = get_state(clock_pid)
    # could be few counts above due
    assert tick_count > 1000
  end

  test "clock works with N modules" do
    nmodules = 50
    nticks = 10000

    {:ok, clock_pid} = Saladin.Clock.start_link(%{})

    for _ <- 1..nmodules, do: BasicTestModule.start_link(%{clock: clock_pid, hello: self()})

    # Wait for all to be registeres
    wait_for_state(clock_pid, fn state -> MapSet.size(state[:modules]) == nmodules end)

    Saladin.Clock.start_clock(clock_pid)
    for _ <- 1..(nmodules * nticks), do: assert_receive({:hello})
    Saladin.Clock.stop_clock(clock_pid)

    %{tick_count: tick_count} = get_state(clock_pid)
    # could be few counts above due
    assert tick_count > nticks
  end
end
