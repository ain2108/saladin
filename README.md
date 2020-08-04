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

## 
