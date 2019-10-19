defmodule Tapestry.Server do
  use GenServer

  #init
  def start_link do
      GenServer.start_link(__MODULE__, %{neighbors: []})
  end

  def init(state) do
    {:ok, state}
  end

  #join
  def join([], called_list, _from) do called_list end

  def join(to_call_list, called_list, from, level) when level>0 do                            # Recursively get neighbors from the level set in each celled's neighborhood
    [hd | tl] = to_call_list                                              # TODO: pattern match will fail if there is only 1 element
    pid = elem(Map.fetch(hd, :pid), 1)                                    # Get pid of the first entry in to-call list
    res = GenServer.call(pid, {:join, from, level})                       # get a row from neighbor's DHT (call the node, get its neighbors)
    called_list = [hd | called_list]                                      # Add the called node to the called list
    lst = Enum.uniq(List.flatten([tl | res]))                             # Remove duplicate entries
    lst2 = Enum.filter(lst, fn el -> !Enum.member?(called_list, el) end)  # Remove entries from to-call list if they are in the called list
    lst2 = Enum.filter(lst2, fn x -> x != [] end)                         # Remove Null neighbors from DHT
    join(lst2, called_list, from, level-1)                                         # Call the next neighbor (recursively)
  end

  def handle_call({:join, from_data, level}, _from, state) do             # TODO: make the DHT an ordered set, for each of its levels (16), so we know what level to hop to
    neighbors = elem(Map.fetch(state, :neighbors), level)                 # get levelth row of neighbors DHT
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
    level = Kernel.max(String.length(from), String.length(to))            # length of hash is equal to its base
    alpha = suffix_distance(from, to)
    res = join([to], [], from)                                            # join to-from nodes together
    neighbors = elem(Map.fetch(state, :neighbors), alpha)                 # Get 1st row of neighbor table

   # Enum.map(neighbors, fn x -> if String.at(x, alpha)==String.at(from, alpha), do: join_from(x, to), else: :ok end))


    neighbors = Enum.filter([neighbors | res], fn x -> x != [] end)       # Add neighbors to existing DHT, Remove Null neighbors
    state = Map.put(state, :neighbors, neighbors)                         # Push the updated DHT to the state variable
    {:reply, state, state}                                                # Send response
  end

  defp check(_hash, "", level), do: :ok end
  defp check("", _hash, level), do: :ok end
  defp check([hf|tf],[ht|tt], level) do
    cond do
      hf == ht -> check(tf,tt,level+1)
      hf != ht -> level
    end
  end

  def suffix_distance(from, to) do    # computes the suffix distance metric
    pid_from = elem(Map.fetch(from, :pid), 1)
    GenServer.call(pid_from, {:prefix_distance, from, to})
  end

  def handle_call({:suffix_distance, from, to}, _from, state) do
    {:reply, check(from,to,0), state}
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
