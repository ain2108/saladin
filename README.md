![image](./saladin_logo.jpeg)
# Saladin

Saladin is a tool for cycle accurate simulation of PLM utilization. For example, given a hardware accelerator, the library aims at making it easy for a designer to determine if Round Robin PLM arbitration yields a Pareto optimal solution.

## Installation
Saladin is powered by Elixir, so you will definately need to install it first.
On MaxOS: 
```bash
brew install elixir
```
For other platforms, please check this link: https://elixir-lang.org/install.html

`mix` tool should be in your path now. To install the project dependencies, please run:
```bash
mix deps.get
```

Finally, to make sure everything is in great shape, please run the tests:
```bash
mix test
```
## Quickstart
Assume we have an accelerator. Let's further assume that the lenght of in-register computation between each PLM access is 1 clock cycle. `consumer` here refers to the consumer of the PLM. Consumer can also be viewed as an instantiation of hardware utilized for the in-register computation. In this example, we have a single PLM bank of size 512 with dual-port enabled, and we have 8 consumers reading from the PLM.
```elixir
config = %{
  bank_size: 512,
  nbanks: nbanks,
  max_value: 65536,
  total_consumers: 8,
  total_work: 512 * 1,
  work_cycles: 1,
  ports_per_bank: 2,
  consumer_update: get_reader_update()
}

finish_time =
  Saladin.Sim.ScratchpadArbitration.run_simulation(config, Saladin.OptimizedArbiterRR, Saladin.BasicScratchpadReader)
```

Thats it! Finish time will tell you the clock cycle that when the last piece of work was completed.

Few more things. Apart from config, `Saladin.Sim.ScratchpadArbitration.run_simulation` utility requires you to provide the arbiter module and the consumer module. Here I am using the built in  `Saladin.OptimizedArbiterRR` and `Saladin.BasicScratchpadReader`, but it should not be hard to provide your own.

Finally, `consumer_update` field in the config is a tuple, with the first component being a function that is used to update the state of the consumer at each iteration, and the second component being some state that the updater function might want to have.
`get_reader_update()` I implemented like so:
```elixir
def get_reader_update() do

  # Function to update the state of the consumer. Returns the updated `state`, the `addr` to request on this iteration,
  # and if after this iteration we are `done`
  update_fun = fn state ->
    addr = state.cur_addr
    done = addr + state.total_consumers < state.total_work
    state = Map.update!(state, :cur_addr, &(&1 + state.total_consumers))
    {state, addr, done}
  end

  # Additional state that that the updater might find useful. In this case we leave it empty.
  update_state = %{}

  {update_fun, update_state}
end
```

## Docs

This section covers how to use the primitives provided by Saladin to build your own custom simulations. 

### General Concepts

Saladin is powered by Elixir/Erlang. The main reason for this is the Actor model. Each hardware module is modelled in Saladin as an Erlang process. Signal exchange is implemented using interprocess messaging. Saladin handles most of the plumbing under the cover, allowing the library user to design custom modules with relative ease.

### Generic Module Process: Saladin.Module
To simplify the process of describing custom hardware modules, Saladin provides the `Saladin.Module` functionality. An example of a `Saladin.Module` is the `Saladin.SimpleArbiterRR`:
```elixir
defmodule Saladin.SimpleArbiterRR do
  use Saladin.Module
  # ...
end
```
Using a `Saladin.Module` bring a lot of functionality necessary to integrate the custom module with other Saladin modules. The only requirement is that the custom module defines a `run(state)` funtion, and optionally a `reset(state)` function. Here is how `Saladin.SimpleArbiterRR.reset` is defined:
```elixir
def reset(state) do

  # Representation for the PLM
  plm = :ets.new(:buckets_registry, [:set, :private])

  plm_init = Map.get(state.plm_config, :plm_init, [])

  # Initialize the PLM
  for addr <- 0..(state.plm_config.nbanks * state.plm_config.bank_size - 1),
      do: :ets.insert(plm, {addr, 0})

  # Update PLM with init values
  for addr_value <- plm_init do
    :ets.insert(plm, addr_value)
  end

  # Wait for all consumers to register
  state = state |> Map.put(:consumers, %{}) |> Map.put(:plm, plm) |> Map.put(:cur_consumer_i, 0)
  wait_consumer_registration(state, 0, state.num_consumers)
  end
```

Elixir is a functional language. It is therefore mendatory to keep passing `state` everywhere. At first it might seem like a hastle, but immutability of Elixir prevents us from fighting a log of horrible bugs. So its a small price to pay. The most dangerous place where the state can be forgotten is the invocation of the `wait(state)` function that can be found in `Saladin.Utils`, but is imported automatically with `Saladin.Module`. This is a very imporant function as it tells the `Saladin.Clock` module that the work for this clock cycle has been completed, and that your module is ready for the next clock cycle. 

### Clock Process: Saladin.Clock

`Saladin.Clock` is the process that models the circuit clock, and every simulation will likely be using one.
```elixir
{:ok, clock_pid} = Saladin.Clock.start_link(%{})
```
The `clock_pid` is the identifier that is used to refer to the clock process; it should be passed to all the other `Saladin.Module`'s at startup.
```elixir
{:ok, scratchpad_pid, _} =
  Saladin.SimpleArbiterRR.start_link(%{
    clock: clock_pid,
    plm_config: plm_config,
    num_consumers: 1
  })
```
