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
    state = Saladin.Utils.get_state(pid)
    %{modules: modules, running: running} = state
    assert running == false
    assert MapSet.member?(modules, self())
  end

  test "clock module starts and stops running on :start and :stop" do
    {:ok, pid} = Saladin.Clock.start_link(%{})

    send(pid, {:start})
    state = Saladin.Utils.get_state(pid)
    %{modules: _, running: running} = state
    assert running == true

    send(pid, {:stop})
    state = Saladin.Utils.get_state(pid)
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

  test "module registers with the clock correctly" do
    {:ok, clock_pid} = Saladin.Clock.start_link(%{})
    {:ok, module_pid, _} = BasicTestModule.start_link(%{clock: clock_pid})
    Saladin.Utils.wait_for_state(clock_pid, &MapSet.member?(&1[:modules], module_pid))
  end

  test "clock sends ticks to the module" do
    {:ok, clock_pid} = Saladin.Clock.start_link(%{})
    {:ok, module_pid, _} = BasicTestModule.start_link(%{clock: clock_pid, hello: self()})
    Saladin.Utils.wait_for_state(clock_pid, &MapSet.member?(&1[:modules], module_pid))
    Saladin.Clock.start_clock(clock_pid)
    assert_receive {:hello}
  end

  test "clock ticks the module 1000 times" do
    {:ok, clock_pid} = Saladin.Clock.start_link(%{})
    {:ok, module_pid, _} = BasicTestModule.start_link(%{clock: clock_pid, hello: self()})
    Saladin.Utils.wait_for_state(clock_pid, &MapSet.member?(&1[:modules], module_pid))
    Saladin.Clock.start_clock(clock_pid)
    for _ <- 0..1000, do: assert_receive({:hello})
    Saladin.Clock.stop_clock(clock_pid)

    %{tick_count: tick_count} = Saladin.Utils.get_state(clock_pid)
    # could be few counts above due
    assert tick_count > 1000
  end

  test "clock works with 50 modules and 10_000 ticks" do
    nmodules = 50
    nticks = 10_000

    {:ok, clock_pid} = Saladin.Clock.start_link(%{})

    for _ <- 1..nmodules, do: BasicTestModule.start_link(%{clock: clock_pid, hello: self()})

    # Wait for all to be registeres
    Saladin.Utils.wait_for_state(clock_pid, fn state ->
      MapSet.size(state[:modules]) == nmodules
    end)

    Saladin.Clock.start_clock(clock_pid)
    for _ <- 1..(nmodules * nticks), do: assert_receive({:hello})
    Saladin.Clock.stop_clock(clock_pid)

    %{tick_count: tick_count} = Saladin.Utils.get_state(clock_pid)
    # could be few counts above due
    assert tick_count >= nticks
  end
end
