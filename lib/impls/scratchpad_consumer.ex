defmodule Saladin.BasicScratchpadReader do
  use Saladin.Module

  def reset(state) do
    scratchpad_input = Saladin.ArbiterInterface.register_consumer(state.scratchpad_pid, state)

    state
    |> Map.put(:scratchpad_input, scratchpad_input)
    |> Map.put(:cur_addr, state.consumer_id)
    |> Map.put(:prev_read_value, nil)
  end

  defp do_work(state, cur_work_cycle, total_work_cycles)
       when cur_work_cycle >= total_work_cycles do
    state
  end

  defp do_work(state, cur_work_cycle, total_work_cycles)
       when cur_work_cycle < total_work_cycles do
    state = wait(state)
    do_work(state, cur_work_cycle + 1, total_work_cycles)
  end

  defp spin(state) do
    wait(state) |> spin()
  end

  def run(state) do
    tester_pid = state.tester_pid
    scratchpad_input = state.scratchpad_input
    work_cycles = state.work_cycles

    {state, addr, done} = state.update.(state)

    # Read the value
    {state, read_value} = Saladin.ArbiterInterface.read(scratchpad_input, addr, state)
    state = %{state | prev_read_value: read_value}

    # Simulate work for # work cycles
    state = do_work(state, 0, work_cycles)

    # Continue work if needed
    if done do
      run(state)
    else
      send(tester_pid, {:consumer_done, state.consumer_id, state.tick_number})
      spin(state)
    end
  end
end
