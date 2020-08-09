defmodule Saladin.OptimizedArbiterRR do
  use Saladin.Module

  defmodule Event do
    defstruct [:arbiter_pid, :port, :consumer_pid, :tick_number]
  end

  defp collect_event(state, consumer_pid, port) do
    collect(state, %Saladin.OptimizedArbiterRR.Event{
      arbiter_pid: self(),
      port: port,
      consumer_pid: consumer_pid,
      tick_number: state.tick_number
    })
  end

  defp wait_consumer_registration(state, cur, num_consumers) do
    # Register consumers
    if cur < num_consumers do
      receive do
        {:register_consumer, consumer_pid, consumer_input} ->
          send(consumer_pid, {:register_consumer_ok, state.input})

          # Add the consumer_pid to the array of consumers
          Map.update!(state, :consumers, &(&1 |> Map.put(cur, consumer_input)))
          |> wait_consumer_registration(cur + 1, num_consumers)
      after
        5_000 ->
          Process.exit(
            self(),
            "Missing consumer registration. Make sure all scratchpad consumers send :register_consumer"
          )
      end
    else
      state
    end
  end

  def reset(state) do
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

  def handle_request(state, cur_consumer, port, _bank_id) do
    tick_number = state.tick_number
    plm = state.plm

    receive do
      # Notice the strict <, req_tick_number is the cycle on which the consumer was driving register inputs
      # req_tick_number + 1 is the earliest cycle when request register value is available to the arbitrator
      {:read, addr, pid, req_tick_number}
      when req_tick_number < tick_number and pid == cur_consumer ->
        [{_, value}] = :ets.lookup(plm, addr)

        # tick_number -- arbiter submits request to PLM
        # tick_number + 1 -- PLM returns the value, control logic routes the value to the consumer's response register
        # tick_number + 2 -- Consumer can use the value in the response register
        Saladin.Module.Input.drive(pid, {:read_done, addr, value, tick_number + 2})
        collect_event(state, cur_consumer, port)
        :ok

      {:write, addr, value, pid, req_tick_number}
      when req_tick_number < tick_number and pid == cur_consumer ->
        :ets.insert(plm, {addr, value})

        Saladin.Module.Input.drive(pid, {:write_done, addr, value, tick_number + 2})
        collect_event(state, cur_consumer, port)
        :ok
    after
      0 -> :ok
    end
  end

  def generate_ids_for_bank(pivot, ports_per_bank, num_consumers) do
    split = div(num_consumers, ports_per_bank)

    0..(ports_per_bank - 1)
    |> Enum.map(fn i ->
      rem(pivot + split * i, num_consumers)
    end)
  end

  def generate_request_candidates(pivot, ports_per_bank, num_consumers, nbanks) do
    0..(nbanks - 1)
    |> Enum.map(fn bank_id ->
      {bank_id, generate_ids_for_bank(pivot + bank_id, ports_per_bank, num_consumers)}
    end)
  end

  def run(state) do
    # The pivot that defines
    pivot = state.cur_consumer_i
    ports_per_bank = Map.get(state.plm_config, :ports_per_bank, 1)

    # For each bank generate the ids that its ports are sensitive to
    request_candidates =
      generate_request_candidates(
        pivot,
        ports_per_bank,
        state.num_consumers,
        state.plm_config.nbanks
      )

    # IO.puts(:stderr, "#{Vinspect(request_candidates)}")

    # Our goal is to collect request_candidates = [{bank0, [cid0, cid2]}, {bank1, [cid1, cid2]}]
    for {bank_id, cids} <- request_candidates do
      cids
      |> Enum.with_index()
      |> Enum.each(fn {cid, port} ->
        cur_consumer = state.consumers[cid]
        :ok = Saladin.OptimizedArbiterRR.handle_request(state, cur_consumer, port, bank_id)
      end)
    end

    # After arbiter submites the request to PLM on cycle n, it can move on to the next consumer on cycle n+1
    # So need to wait for a single clock cycle
    state = wait(state)
    state |> Map.update!(:cur_consumer_i, &rem(&1 + 1, state.num_consumers)) |> run()
  end
end
