defmodule DataEmitter do
  # Client API
  @spec start_link(any) :: {:ok, pid}
  def start_link(filename) do
    pid = self()
    {:ok, module_pid} = Task.start_link(fn -> init(pid, filename) end)

    receive do
      {:ready, pid} when pid == module_pid -> {:ok, module_pid}
    after
      5_000 -> exit("DataEmitter not started")
    end
  end

  def emit(:events, emitter_pid, events, parser) do
    send(emitter_pid, {:events, self(), events, parser})

    receive do
      {:ok, pid} when pid == emitter_pid -> :ok
    after
      5_000 -> exit("Data emitter not responding")
    end
  end

  def emit(:sim_start, emitter_pid, sim_config) do
    send(emitter_pid, {:sim_start, self(), sim_config})

    receive do
      {:ok, pid} when pid == emitter_pid -> :ok
    after
      5_000 -> exit("Data emitter not responding")
    end
  end

  @spec emit(:sim_end, atom | pid | port | {atom, atom}) :: :ok
  def emit(:sim_end, emitter_pid) do
    send(emitter_pid, {:sim_end, self()})

    receive do
      {:ok, pid} when pid == emitter_pid -> :ok
    after
      5_000 -> exit("Data emitter not responding")
    end
  end

  @spec stop(atom | pid | port | {atom, atom}) :: :ok
  def stop(emitter_pid) do
    send(emitter_pid, {:stop, self()})

    receive do
      {:ok, pid} when pid == emitter_pid -> :ok
    end
  end

  # Server code

  defp init(parent, filename) do
    {:ok, file} = File.open(filename, [:write])
    send(parent, {:ready, self()})
    run(%{file: file})
  end

  defp write(:events, file, events, event_parser) do
    # csv_string =
    #   (Tuple.to_list(payload) |> Enum.reduce("", fn token, acc -> acc <> token <> "," end)) <>
    #     "\n"

    string = event_parser.parse(events)

    IO.binwrite(file, string)
  end

  defp write(:sim_start, file, sim_config) do
    IO.binwrite(file, "===SIMBEGIN\n")
    IO.binwrite(file, "*" <> sim_config <> "\n")
  end

  defp write(:sim_end, file) do
    IO.binwrite(file, "===SIMEND\n")
  end

  defp stop(:end, src_pid, file) do
    File.close(file)
    send(src_pid, {:ok, self()})
    exit(:normal)
  end

  defp ack(src_pid) do
    send(src_pid, {:ok, self()})
  end

  @spec run(any) :: any
  def run(state) do
    receive do
      {:events, src_pid, events, parser} ->
        write(:events, state.file, events, parser)
        ack(src_pid)

      {:sim_start, src_pid, sim_config} ->
        write(:sim_start, state.file, sim_config)
        ack(src_pid)

      {:sim_end, src_pid} ->
        write(:sim_end, state.file)
        ack(src_pid)

      {:stop, src_pid} ->
        stop(:end, src_pid, state.file)
    end

    run(state)
  end
end
