defmodule Saladin.ArbiterRRBehavioralTests do
  use ExUnit.Case

  def get_reader_update() do
    update_fun = fn state ->
      addr = state.cur_addr
      done = addr + state.total_consumers < state.total_work
      state = Map.update!(state, :cur_addr, &(&1 + state.total_consumers))
      {state, addr, done}
    end

    update_state = %{}

    {update_fun, update_state}
  end

  test "SimpleArbiterRR behaviour test" do
    bank_size = 8
    nbanks = 1
    arbiter = Saladin.SimpleArbiterRR
    consumer_module = Saladin.BasicScratchpadReader

    config = %{
      bank_size: bank_size,
      nbanks: nbanks,
      max_value: 65536,
      total_consumers: 2,
      total_work: bank_size * nbanks,
      work_cycles: 1,
      consumer_update: get_reader_update()
    }

    finish_time =
      Saladin.Sim.ScratchpadArbitration.run_simulation(config, arbiter, consumer_module)

    assert finish_time == 18
  end

  test "OptimizedArbiterRR behaviour test 2 consumers" do
    bank_size = 8
    nbanks = 1
    arbiter = Saladin.OptimizedArbiterRR
    consumer_module = Saladin.BasicScratchpadReader

    config = %{
      bank_size: bank_size,
      nbanks: nbanks,
      max_value: 65536,
      total_consumers: 2,
      total_work: bank_size * nbanks,
      work_cycles: 1,
      consumer_update: get_reader_update()
    }

    finish_time =
      Saladin.Sim.ScratchpadArbitration.run_simulation(config, arbiter, consumer_module)

    assert finish_time == 17
  end

  test "OptimizedArbiterRR behaviour test 4 consumers" do
    bank_size = 8
    nbanks = 1
    arbiter = Saladin.OptimizedArbiterRR
    consumer_module = Saladin.BasicScratchpadReader

    config = %{
      bank_size: bank_size,
      nbanks: nbanks,
      max_value: 65536,
      total_consumers: 4,
      total_work: bank_size * nbanks,
      work_cycles: 1,
      consumer_update: get_reader_update()
    }

    finish_time =
      Saladin.Sim.ScratchpadArbitration.run_simulation(config, arbiter, consumer_module)

    assert finish_time == 11
  end

  test "OptimizedArbiterRR behaviour test 8 consumers and 2 ports" do
    bank_size = 16
    nbanks = 1
    ports_per_bank = 2
    arbiter = Saladin.OptimizedArbiterRR
    consumer_module = Saladin.BasicScratchpadReader

    config = %{
      bank_size: bank_size,
      nbanks: nbanks,
      max_value: 65536,
      total_consumers: 8,
      total_work: bank_size * nbanks,
      work_cycles: 1,
      ports_per_bank: ports_per_bank,
      consumer_update: get_reader_update()
    }

    finish_time =
      Saladin.Sim.ScratchpadArbitration.run_simulation(config, arbiter, consumer_module)

    assert finish_time == 11
  end
end
