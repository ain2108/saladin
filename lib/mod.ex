defmodule Saladin.Module do
  @spec start_link(any) :: {:ok, pid}
  def start_link(ports) do
    # Want to make sure our simulation crashes in case a process crashes
    Task.start_link(fn -> reset(%{:ports => ports}) end)
  end

  defp reset state do
    IO.puts("reset")
    wait(state)
    IO.puts("received first clock pulse")
    loop(state)
  end

  defp wait state, timeout \\ 10_000 do
    clock_pid = state[:ports][:clock]

    # Tell the clock you are ready for the next cycle
    send(clock_pid, {:ready, self()})

    receive do
      {:tiktok} -> IO.puts("tiktok")
      {:reset} -> reset(state)
    after
      timeout ->
        Process.exit(self(), "no clock signal has been received")
    end
  end

  defp loop(state) do
    # Main compute loop

    # Block on
    receive do
      {:hello} -> IO.puts("Hello world!")
    after
      0 -> :ok
    end

    # Wait for the next clock cycle
    wait(state)

    # Get back into the loop
    loop(state)
  end
end
