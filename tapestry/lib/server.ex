defmodule Tapestry.Server do
  use GenServer

  def start_link do
      GenServer.start_link(__MODULE__, %{neighbors: []})
  end

  def init(state) do
    {:ok, state}
  end

  def join([], called_list, _from) do called_list end
  def join(to_call_list, called_list, from) do
    [hd | tl] = to_call_list
    pid = elem(Map.fetch(hd, :pid), 1)
    res = GenServer.call(pid, {:join, from})
    called_list = [hd | called_list]
    lst = Enum.uniq(List.flatten([tl | res]))
    lst2 = Enum.filter(lst, fn el -> !Enum.member?(called_list, el) end)
    join(lst2, called_list, from)
  end

  def handle_call({:join, from_data}, _from, state) do
    neighbors = elem(Map.fetch(state, :neighbors), 1)
    neighbors2 = [from_data | neighbors]
    neighbors2 = Enum.uniq(neighbors2)
    neighbors2 = Enum.filter(neighbors2, fn x -> x != [] end)
    state = Map.put(state, :neighbors, neighbors2)
    {:reply, neighbors, state}
  end

  def join_from(from, to) do
    pid_from = elem(Map.fetch(from, :pid), 1)
    GenServer.cast(pid_from, {:join_from, from, to})
  end

  def handle_cast({:join_from, from, to}, state) do
    res = join([to], [], from)
    neighbors = elem(Map.fetch(state, :neighbors), 1)
    neighbors = Enum.filter([neighbors | res], fn x -> x != [] end)
    state = Map.put(state, :neighbors, neighbors)
    {:noreply, state}
  end

  def get_neighbors(node) do
    pid = elem(Map.fetch(node, :pid), 1)
    GenServer.call(pid, :get_neighbors)
  end

  def handle_call(:get_neighbors, _from, state) do
    neighbors = elem(Map.fetch(state, :neighbors), 1)
    {:reply, neighbors, state}
  end
end
