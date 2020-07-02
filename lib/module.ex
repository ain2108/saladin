defmodule Saladin.Module do
  @callback reset(Map.t()) :: {:ok, term} | {:error, String.t()}
  @callback run(Map.t()) :: any

  # When you call use in your module, the __using__ macro is called.
  defmacro __using__(_params) do
    quote do
      # User modules must implement the Saladin.Module callbacks
      @behaviour Saladin.Module

      # Define implementation for user modules to use
      def reset(state), do: {:ok, "default_reset"}
      def run(state), do: {:error, "not implemented"}

      def start_link(ports) do
        # Want to make sure our simulation crashes in case a process crashes
        Task.start_link(fn -> reset_sequence(%{:ports => ports}) end)
      end

      defp reset_sequence(state) do
        reset(state)
        wait(state)
        run(state)
      end

      defp wait(state, timeout \\ 10_000) do
        clock_pid = state[:ports][:clock]

        # Tell the clock you are ready for the next cycle
        send(clock_pid, {:ready, self()})

        receive do
          {:tiktok} -> {:ok}
          {:reset} -> reset_sequence(state)
        after
          timeout ->
            Process.exit(self(), "no clock signal has been received")
        end
      end

      # Defoverridable makes the given functions in the current module overridable
      # Without defoverridable, new definitions of greet will not be picked up
      defoverridable reset: 1, run: 1
    end
  end
end
