defmodule Tapestry.Server do
  use GenServer

  def start_link do
      GenServer.start_link(__MODULE__, %{neighbors: []})
  end

  def add_neighbors(pid, list) do
    GenServer.cast(pid, {:add_neighbors, list})
  end

  def init(state) do
    {:ok, state}
  end

  #No checks on if neighbor valid done
  def handle_cast({:add_neighbors, list}, state) do
    neighbors = elem(Map.fetch(state, :neighbors), 1)
    neighbors = [list | neighbors]
    neighbors = List.flatten(neighbors)
    state = Map.put(state, :neighbors, neighbors)
    {:noreply, state}
  end
end
