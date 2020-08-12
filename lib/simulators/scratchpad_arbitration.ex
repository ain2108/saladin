defmodule Saladin.Simulator.ScratchpadArbitration do
  defimpl String.Chars, for: PID do
    def to_string(pid) do
      inspect(pid) |> String.split(".") |> Enum.at(1)
    end
  end

  defmodule EventParser do
    def parse(events) do
      Enum.reduce(events, "", fn e, acc ->
        case e do
          %Saladin.BasicScratchpadReader.Event{} ->
            acc <> "c,consumer#{e.consumer_pid},#{e.op},#{e.tick_number}\n"

          %Saladin.OptimizedArbiterRR.Event{} ->
            acc <>
              "a,arbiter#{e.arbiter_pid}_#{e.port},consumer#{e.consumer_pid},#{e.tick_number}\n"

          # If the event is unmatched, just ignore it.
          _ ->
            acc
        end
      end)
    end
  end

  def main(args \\ []) do
    args
    |> parse_args()
    |> _main()
  end

  defp parse_args(args) do
    {opts, word, _} =
      args
      |> OptionParser.parse(strict: [file: :string, config: :string])

    {opts, List.to_string(word)}
  end

  defp get_reader_update() do
    update_fun = fn state ->
      addr = state.cur_addr
      done = addr + state.total_consumers < state.total_work
      state = Map.update!(state, :cur_addr, &(&1 + state.total_consumers))
      {state, addr, done}
    end

    update_state = %{}

    {update_fun, update_state}
  end

  defp get_json(filename) do
    with {:ok, body} <- File.read(filename), {:ok, json} <- Poison.decode(body), do: {:ok, json}
  end

  defp load_module(module_name) do
    try do
      String.to_existing_atom("Elixir." <> module_name)
    rescue
      ArgumentError ->
        IO.puts(:stderr, "Module {module_name} cannot be found. Specify an existing module.")
        exit(:normal)
    end
  end

  defp get_sims(config_file) do
    {:ok, sims} = get_json(config_file)

    if length(sims["simulations"]) == 0 do
      IO.puts(:stderr, "No simulations provided in the config. Nothing to do")
      exit(:normal)
    else
      sims["simulations"]
    end
  end

  defp run_simulation(collector_pid, sim_config) do
    bank_size = sim_config["bank_size"]
    nbanks = sim_config["nbanks"]
    ports_per_bank = sim_config["ports_per_bank"]
    total_consumers = sim_config["total_consumers"]
    work_cycles = sim_config["work_cycles"]
    arbiter_module = load_module(sim_config["arbiter_module"])
    consumer_module = load_module(sim_config["consumer_module"])

    config = %{
      bank_size: bank_size,
      nbanks: nbanks,
      max_value: 65536,
      total_consumers: total_consumers,
      total_work: bank_size * nbanks,
      work_cycles: work_cycles,
      ports_per_bank: ports_per_bank,
      consumer_update: get_reader_update(),
      collector: collector_pid
    }

    Saladin.Sim.ScratchpadArbitration.run_simulation(config, arbiter_module, consumer_module)
  end

  defp _main({opts, _}) do
    file = Keyword.get(opts, :file, "data/data-#{:os.system_time(:millisecond)}")
    config_file = opts[:config]

    sims = get_sims(config_file)

    # Create directory if needed
    File.mkdir_p!(Path.dirname(file))
    {:ok, collector_pid} = Saladin.EventCollector.start_link()
    {:ok, emitter_pid} = Saladin.Data.CsvEmitter.start_link(file)

    for sim_config <- sims do
      finish_time = run_simulation(collector_pid, sim_config)

      events = Saladin.EventCollector.get_events(collector_pid)

      IO.puts(:stdio, "Finish cycle: #{finish_time}")

      :ok =
        Saladin.Data.CsvEmitter.emit(
          :sim_start,
          emitter_pid,
          "a:#{sim_config["arbiter_module"]} c:#{sim_config["total_consumers"]} w:#{
            sim_config["bank_size"] * sim_config["nbanks"]
          } n:#{sim_config["work_cycles"]}"
        )

      :ok = Saladin.Data.CsvEmitter.emit(:events, emitter_pid, events, EventParser)

      :ok = Saladin.Data.CsvEmitter.emit(:sim_end, emitter_pid)
    end

    :ok = Saladin.Data.CsvEmitter.stop(emitter_pid)

    IO.puts(:stdio, "Data emitted to file:#{file}")
  end
end
