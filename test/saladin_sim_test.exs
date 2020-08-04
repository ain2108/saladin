defmodule Saladin.ArbiterRRBehavioralTests do
  use ExUnit.Case

  test "SimpleArbiterRR behaviour test" do
    bank_size = 8
    nbanks = 1
    arbiter = Saladin.SimpleArbiterRR

    config = %{
      bank_size: bank_size,
      nbanks: nbanks,
      max_value: 65536,
      total_consumers: 2,
      total_work: bank_size * nbanks,
      work_cycles: 1
    }

    finish_time = Saladin.Sim.ScratchpadArbitration.run_simulation(config, arbiter)

    assert finish_time == 18
  end

  test "OptimizedArbiterRR behaviour test 2 consumers" do
    bank_size = 8
    nbanks = 1
    arbiter = Saladin.OptimizedArbiterRR

    config = %{
      bank_size: bank_size,
      nbanks: nbanks,
      max_value: 65536,
      total_consumers: 2,
      total_work: bank_size * nbanks,
      work_cycles: 1
    }

    finish_time = Saladin.Sim.ScratchpadArbitration.run_simulation(config, arbiter)

    assert finish_time == 17
  end

  test "OptimizedArbiterRR behaviour test 4 consumers" do
    bank_size = 8
    nbanks = 1
    arbiter = Saladin.OptimizedArbiterRR

    config = %{
      bank_size: bank_size,
      nbanks: nbanks,
      max_value: 65536,
      total_consumers: 4,
      total_work: bank_size * nbanks,
      work_cycles: 1
    }

    finish_time = Saladin.Sim.ScratchpadArbitration.run_simulation(config, arbiter)

    assert finish_time == 11
  end

  test "OptimizedArbiterRR behaviour test 8 consumers and 2 ports" do
    bank_size = 16
    nbanks = 1
    ports_per_bank = 2
    arbiter = Saladin.OptimizedArbiterRR

    config = %{
      bank_size: bank_size,
      nbanks: nbanks,
      max_value: 65536,
      total_consumers: 8,
      total_work: bank_size * nbanks,
      work_cycles: 1,
      ports_per_bank: ports_per_bank
    }

    finish_time = Saladin.Sim.ScratchpadArbitration.run_simulation(config, arbiter)

    assert finish_time == 11
  end
end
