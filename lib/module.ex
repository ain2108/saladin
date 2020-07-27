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
    iex> {:ok, _, _} = BasicModule.start_link(%{:clock => self()})
    iex> :ok
    :ok

  """
  @callback reset(Map.t()) :: Map.t()
  @callback run(Map.t()) :: no_return

  # When you call use in your module, the __using__ macro is called.
  defmacro __using__(_params) do
    quote do
      # User modules must implement the Saladin.Module callbacks
      @behaviour Saladin.Module

      import Saladin.Utils, only: [wait: 1]

      # Define implementation for user modules to use
      def reset(state), do: state

      def run(state) do
        state = wait(state)
        run(state)
      end

      def start_link(state) do
        # Want to make sure our simulation crashes in case a process crashes
        state = Map.put(state, :_parent, self())

        {:ok, module_pid} = Task.start_link(fn -> init(state) end)

        # Modules send init
        receive do
          {:module_started, input_pid} -> {:ok, module_pid, input_pid}
        end
      end

      defp init(state) do
        # Initialize input queue
        {:ok, input} = Saladin.Module.Input.start_link([])
        send(state[:_parent], {:module_started, input})

        # Register with the clock
        clock_pid = state[:clock]
        send(clock_pid, {:register, self()})

        receive do
          {:registration_ok} -> :ok
        end

        reset_sequence(state |> Map.put(:tick_number, 0) |> Map.put(:input, input))
      end

      defp reset_sequence(state) do
        state = reset(state)
        state = wait(state)
        run(state)
      end

      # Defoverridable makes the given functions in the current module overridable
      # Without defoverridable, new definitions of greet will not be picked up
      defoverridable reset: 1, run: 1
    end
  end
end

defmodule Saladin.Module.Input do
  use GenServer

  # Interface

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def drive(pid, msg) do
    GenServer.call(pid, {:write, msg})
  end

  def read_all(pid) do
    GenServer.call(pid, :read_all)
  end

  # Server (callbacks)

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:read_all, _from, state) do
    {:reply, state, []}
  end

  @impl true
  def handle_call({:write, msg}, _from, state) do
    {:reply, :ok, [msg | state]}
  end
end
