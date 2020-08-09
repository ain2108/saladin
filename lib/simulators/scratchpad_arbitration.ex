defmodule Saladin.Simulator.ScratchpadArbitration do
  defimpl String.Chars, for: PID do
    def to_string(pid) do
      inspect(pid) |> String.split(".") |> Enum.at(1)
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
      |> OptionParser.parse(strict: [file: :string])

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

  defp _main({opts, _}) do
    IO.puts(:stdio, "#{inspect(opts)}")

    file = Keyword.get(opts, :file, "data/data-#{:os.system_time(:millisecond)}")

    # Create directory if needed
    File.mkdir_p!(Path.dirname(file))

    {:ok, collector_pid} = DataCollector.start_link()

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
      consumer_update: get_reader_update(),
      collector: collector_pid
    }

    finish_time =
      Saladin.Sim.ScratchpadArbitration.run_simulation(config, arbiter, consumer_module)

    events = DataCollector.get_events(collector_pid)

    for event <- events do
      IO.puts(:stdio, "#{inspect(event)}\n")
    end

    IO.puts(:stdio, "#{finish_time}")

    defmodule EventParser do
      def parse(events) do
        Enum.reduce(events, "", fn e, acc ->
          case e do
            %Saladin.BasicScratchpadReader.Event{} ->
              acc <> "c,consumer#{e.consumer_pid},#{e.op},#{e.tick_number}\n"

            %Saladin.OptimizedArbiterRR.Event{} ->
              acc <> "a,arbiter#{e.arbiter_pid},consumer#{e.consumer_pid},#{e.tick_number}\n"

            # If the event is unmatched, just ignore it.
            _ ->
              acc
          end
        end)
      end
    end

    {:ok, emitter_pid} = DataEmitter.start_link(file)

    :ok = DataEmitter.emit(:sim_start, emitter_pid, "This and that")

    :ok = DataEmitter.emit(:events, emitter_pid, events, EventParser)

    :ok = DataEmitter.emit(:sim_end, emitter_pid)

    :ok = DataEmitter.stop(emitter_pid)

    IO.puts(:stdio, "Data emitted to file:#{file}")
  end
end
