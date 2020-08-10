defmodule Saladin.EventCollector do
  # Client API

  def start_link() do
    pid = self()
    {:ok, module_pid} = Task.start_link(fn -> init(pid) end)

    receive do
      {:ready, pid} when pid == module_pid -> {:ok, module_pid}
    after
      5_000 -> exit("Saladin.Data.CsvEmitter not started")
    end
  end

  def collect(collector_pid, event) do
    send(collector_pid, {:event, event})
    :ok
    # Don't wait for response
  end

  def get_events(collector_pid) do
    send(collector_pid, {:get_events, self()})

    receive do
      {:events, events} -> events
    end
  end

  def stop(collector_pid) do
    send(collector_pid, {:stop, self()})

    receive do
      {:ok, pid} when pid == collector_pid -> :ok
    end
  end

  # Server code

  defp init(parent) do
    send(parent, {:ready, self()})
    run([])
  end

  defp do_stop(src_pid) do
    send(src_pid, {:ok, self()})
    exit(:normal)
  end

  def run(events) do
    events =
      receive do
        {:event, event} -> [event | events]
        {:stop, src_pid} -> do_stop(src_pid)
        {:get_events, src_pid} -> send(src_pid, {:events, events})
      end

    run(events)
  end
end
