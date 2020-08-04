defmodule Saladin.Sim.ScratchpadArbitration do
  def run_simulation(config, arbiter_module, consumer_module) do
    bank_size = config.bank_size
    nbanks = config.nbanks
    max_value = config.max_value
    total_consumers = config.total_consumers
    total_work = bank_size * nbanks
    work_cycles = config.work_cycles
    ports_per_bank = Map.get(config, :ports_per_bank, 1)

    # Generate the list of values to populate the PLM with
    plm_init = 0..(bank_size - 1) |> Enum.map(&{&1, :rand.uniform(max_value)})

    # Start clock
    {:ok, clock_pid} = Saladin.Clock.start_link(%{})

    # Initialize the ScratchPad
    plm_config = %{
      nbanks: nbanks,
      bank_size: bank_size,
      plm_init: plm_init,
      ports_per_bank: ports_per_bank
    }

    {:ok, scratchpad_pid, _} =
      arbiter_module.start_link(%{
        clock: clock_pid,
        plm_config: plm_config,
        num_consumers: total_consumers
      })

    # Start the consumers
    start_scratchpad_consumer = fn consumer_id ->
      consumer_module.start_link(%{
        clock: clock_pid,
        scratchpad_pid: scratchpad_pid,
        tester_pid: self(),
        consumer_id: consumer_id,
        total_consumers: total_consumers,
        total_work: total_work,
        work_cycles: work_cycles
      })
    end

    consumers =
      0..(total_consumers - 1)
      |> Enum.map(fn consumer_id -> start_scratchpad_consumer.(consumer_id) end)

    # Wait for all modules to register with clock
    Saladin.Utils.wait_for_state(
      clock_pid,
      &MapSet.equal?(
        &1[:modules],
        MapSet.new(
          [scratchpad_pid] ++ Enum.map(consumers, fn {:ok, tester_pid, _} -> tester_pid end)
        )
      )
    )

    Saladin.Clock.start_clock(clock_pid)

    consumer_work_receipts =
      1..total_consumers
      |> Enum.map(fn _ ->
        receive do
          {:consumer_done, consumer_id, tick_number} ->
            {consumer_id, tick_number}
        end
      end)

    finish_time = consumer_work_receipts |> Enum.map(fn {_, tick} -> tick end) |> Enum.max()

    finish_time
  end
end
