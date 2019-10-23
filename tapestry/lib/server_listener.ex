defmodule Tapestry.Server.Listener do
  use GenServer

  def start_link(num_expected, num_received) do
    GenServer.start_link(__MODULE__,  %{num_expected: num_expected, num_received: num_received})
end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:found, jumps, to}, state) do  # Gets called when message is delivered to corret peer
    num_received = elem(Map.fetch(state, :num_received), 1) + 1
    num_expected = elem(Map.fetch(state, :num_expected), 1)
    cond do
      num_received == num_expected ->
        IO.inspect(Enum.join(["done1", to], " "))
        IO.puts 'terminating'
        Tapestry.DynamicSupervisor.terminate_child(self())
      true ->
        IO.inspect(Enum.join(["done2", to, Integer.to_string(jumps)], " "))
        state = Map.put(state, :num_received, num_received)
        {:noreply, state}
    end
  end
end
