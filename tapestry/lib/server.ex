defmodule Tapestry.Server do
  use GenServer

  #init
  def start_link(guid) do
      GenServer.start_link(__MODULE__, %{guid: "#{guid}", neighbors: []})
  end

  def init(state) do
    {:ok, state}
  end

  #join
  def join([], called_list, _from) do called_list end

  def join(to_call_list, called_list, from) do                            # Recursively get neighbors from the level set in each celled's neighborhood
    [hd | tl] = to_call_list                                              # TODO: pattern match will fail if there is only 1 element
    pid = elem(Map.fetch(hd, :pid), 1)                                    # Get pid of the first entry in on-call list
    res = GenServer.call(pid, {:join, from})                              # get a row from neighbor's DHT (call the node, get its neighbors)
    called_list = [hd | called_list]                                      # Add the called node to the called list
    lst = Enum.uniq(List.flatten([tl | res]))                             # Remove duplicate entries
    lst2 = Enum.filter(lst, fn el -> !Enum.member?(called_list, el) end)  # Remove entries from to-call list if they are in the called list
    lst2 = Enum.filter(lst2, fn x -> x != [] end)                         # Remove Null neighbors from DHT
    join(lst2, called_list, from)                                         # Call the next neighbor (recursively)
  end

  def handle_call({:join, from_data}, _from, state) do
    alpha = 1 # alpha is the level of the table that we want
    neighbors = elem(Map.fetch(state, :neighbors), alpha)                 # get alphath row of neighbors DHT
    neighbors2 = [from_data | neighbors]                                  # Add neighbors to your own DHT
    neighbors2 = Enum.uniq(neighbors2)                                    # remove duplicates
    neighbors2 = Enum.filter(neighbors2, fn x -> x != [] end)             # remove Null neighbors
    state = Map.put(state, :neighbors, neighbors2)                        # Update the DHT with the new data
    {:reply, neighbors, state}                                            # Send response
  end

  def join_from(from, to) do
    pid_from = elem(Map.fetch(from, :pid), 1)
    GenServer.call(pid_from, {:join_from, from, to})
  end

  def handle_call({:join_from, from, to}, _from, state) do
    res = join([to], [], from)                                            # join to-from nodes together
    neighbors = elem(Map.fetch(state, :neighbors), 1)                     # Get1st row of neighbor table
    neighbors = Enum.filter([neighbors | res], fn x -> x != [] end)       # Add neighbors to existing DHT, Remove Null neighbors
    state = Map.put(state, :neighbors, neighbors)                         # Push the updated DHT to the state variable
    {:reply, state, state}                                                # Send response
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
