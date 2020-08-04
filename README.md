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

## Getting started
While the library will provide solutions 

