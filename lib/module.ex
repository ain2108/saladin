defmodule Saladin.Module do
  @moduledoc """
  Saladin.Module models the behaviour of a synchronous RTL module. User can override the
  run/1 function and the reset/1, both accepting a state map. The state map should at a minimum
  contain state[:clock], the pid of a Saladin.Clock process. The user of the module gets the
  access to a wait/1 which models a wait for the next rising edge of the clock.

  ## Example

    iex> defmodule BasicModule do
    ...>  use Saladin.Module
    ...>  def run(state) do
    ...>   wait(state)
    ...>   run(state)
    ...>  end
    ...> end
    iex> {:ok, _} = BasicModule.start_link(%{:clock => self()})
    iex> :ok
    :ok

  """
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

      def start_link(state) do
        # Want to make sure our simulation crashes in case a process crashes
        Task.start_link(fn -> init(state) end)
      end

      defp init(state) do
        # Register with the clock
        clock_pid = state[:clock]
        send(clock_pid, {:register, self()})

        receive do
          {:registration_ok} -> :ok
        end

        reset_sequence(state)
      end

      defp reset_sequence(state) do
        reset(state)
        wait(state)
        run(state)
      end

      defp wait(state, timeout \\ 10_000) do
        clock_pid = state[:clock]

        # Tell the clock you are ready for the next cycle
        send(clock_pid, {:ready, self()})

        receive do
          {:tick} -> {:ok}
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
