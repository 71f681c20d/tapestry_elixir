defmodule Tapestry.Server.Listener do
  use GenServer

  def start_link(num_expected, num_received) do
    GenServer.start_link(__MODULE__,  %{num_expected: num_expected, num_received: num_received, num_jump_list: []})
end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:found, jumps, to}, state) do  # Gets called when message is delivered to corret peer
    num_received = elem(Map.fetch(state, :num_received), 1) + 1
    num_expected = elem(Map.fetch(state, :num_expected), 1)
    cond do
      num_received == num_expected ->
        #IO.inspect(Enum.join(["done", to], " "))
        #IO.puts 'terminating'
        jump_list = elem(Map.fetch(state, :num_jump_list), 1)
        max_jumps = Enum.max(jump_list)
        IO.inspect(Enum.join(["The max number of jumps was:", Integer.to_string(max_jumps)], " "))
        Tapestry.DynamicSupervisor.terminate_child(self())
      true ->
        #IO.inspect(Enum.join(["done", to, Integer.to_string(jumps)], " "))
        jump_list = elem(Map.fetch(state, :num_jump_list), 1)
        jump_list = [ jumps | jump_list]
        state = Map.put(state, :num_jump_list, jump_list)
        state = Map.put(state, :num_received, num_received)
        {:noreply, state}
    end
  end
end
