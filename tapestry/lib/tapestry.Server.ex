defmodule Tapestry.Server do
  use GenServer

  #init
  def start_link (guid) do
      GenServer.start_link(__MODULE__, %{guid: "#{guid}", neighbors: []})
  end

  def init(state) do
    {:ok, state}
  end

  defp tidy_DHT(from) do    # Tidy it up
     pid_from = elem(Map.fetch(from, :pid), 1)
    GenServer.call(pid_from, {:tidy_DHT})
  end

  def handle_call({:tidy_DHT}, _from, state) do
    for y <- Enum.filter(elem(Map.fetch(state, :neighbors), 1), fn x -> x != [] end), do: y |> Enum.uniq
  end

  #join
  def join([], called_list, _from) do called_list end

  def join([hd | tl], called_list, from, level) do                            # Recursively get neighbors from the level set in each celled's neighborhood
    level = Kernel.max(level,0)
    pid = elem(Map.fetch(hd, :pid), 1)                                    # Get pid of the first entry in to-call list
    res = GenServer.call(pid, {:join, from, level})                       # get a row from neighbor's DHT (call the node, get its neighbors)
    called_list = [hd | called_list]                                      # Add the called node to the called list
    lst = Enum.uniq(List.flatten([tl | res]))                             # Remove duplicate entries
    lst2 = Enum.filter(lst, fn el -> !Enum.member?(called_list, el) end)  # Remove entries from to-call list if they are in the called list
    join(lst2, called_list, from, level-1)                                # Call the next neighbor (recursively)
  end

  def handle_call({:join, from_data, level}, _from, state) do               # TODO: make the DHT an ordered set, for each of its levels (16), so we know what level to hop to
    neighbors = elem(elem(Map.fetch(state, :neighbors), 1), level)
    neighbors2 = [[from_data] | neighbors]                                  # Add neighbors to your own DHT
    state = Map.put(state, :neighbors, neighbors2)                          # Update the DHT with the new data
    {:reply, neighbors, state}                                              # Send response
  end

  def join_from(from, to) do
    pid_from = elem(Map.fetch(from, :pid), 1)
    GenServer.call(pid_from, {:join_from, from, to})
  end

  def handle_call({:join_from, from, to}, _from, state) do
    #level = Kernel.max(String.length(from), String.length(to))            # length of hash is equal to its base
    alpha = suffix_distance(from, to)
    res = join([to], [], from, alpha)                                     # join to-from nodes together
    neighbors = elem(Map.fetch(state, :neighbors), 1)                     # Get 1st row of neighbor table TODO why only the 1st row??
    # Enum.map(neighbors, fn x -> if String.at(x, alpha)==String.at(from, alpha), do: join_from(x, to), else: :ok end))
    neighbors = [neighbors | res]                                         # Add neighbors to existing DHT, Remove Null neighbors
    state = Map.put(state, :neighbors, neighbors)                         # Push the updated DHT to the state variable
    {:reply, state, state}                                                # Send response
  end

  defp check(_hash, "", level), do: :ok
  defp check("", _hash, level), do: :ok
  defp check(from_hash,to_hash, level) do
    {hf,tf} = from_hash |> String.next_grapheme
    {ht,tt} = to_hash |> String.next_grapheme
    cond do
      hf == ht -> check(tf,tt,level+1)
      hf != ht -> level
    end
  end

  defp suffix_distance(from, to) do    # computes the suffix distance metric
    pid_from = elem(Map.fetch(from, :pid), 1)
    from_guid = elem(Map.fetch(from, :uid), 1)
    to_guid = elem(Map.fetch(to, :uid), 1)
    GenServer.call(pid_from, {:suffix_distance, from_guid, to_guid})
  end

  def handle_call({:suffix_distance, from_guid, to_guid}, _from, state) do
    {:reply, check(from_guid,to_guid,0), state}
  end

  def get_neighbors(node) do
    pid = elem(Map.fetch(node, :pid), 1)
    GenServer.call(pid, :get_neighbors)
  end

  def handle_call(:get_neighbors, _from, state) do
    neighbors = elem(Map.fetch(state, :neighbors), 1)
    {:reply, neighbors, state}
  end

  def route_to_object(from, to) do
    object_router(from, to, suffix_distance(from, to))
  end

  defp object_router(from, to, level) do # Uses some multi-casting, as suggested in the paper
    {_,neighbors} = elem(Map.fetch(state, :neighbors), level) # TODO Lee can you verify this pattern match?
    if level > 0, do: Enum.map(neighbors, fn x -> if check(x, to)>level, do: GenServer.cast(elem(Map.fetch(x, :pid), 1), {:object_router, x, level-1}) end)  # TODO: get x's pid to cast
    [from]  # Evals to the closest possible node, and each node along the way
  end

  def handle_cast({:object_router, from, to, level}, _from, state) do
    from_guid = elem(Map.fetch(state, :guid), 1)
    dest_guid = elem(Map.fetch(to, :uid), 1)
    # object_router(from, to, level-1)
    {_,neighbors} = elem(Map.fetch(state, :neighbors), level) # TODO Lee can you verify this pattern match?
    if level > 0, do: Enum.map(neighbors, fn x -> if check(x, to)>level, do: GenServer.cast(elem(Map.fetch(x, :pid), 1), {:object_router, x, level-1}) end)  # TODO: get x's pid to cast
    [from]  # Evals to the closest possible node, and each node along the way
  end

  def route_to_node(from, to) do
    node_router(from, to, suffix_distance(from, to))
  end

  def node_router(from, to, level) do  # TODO: Ensure exact suffix match
    {_,neighbors} = elem(Map.fetch(state, :neighbors), level)
    if level > 0, do: Enum.map(neighbors, fn x -> if check(x, to)>level, do: GenServer.cast(elem(Map.fetch(x, :pid), 1), {:node_router, x, level-1}) end) # TODO: get x's pid to cast
    [from]  # Evals to the closest possible node, and each node along the way
  end

  def handle_cast({:node_router, to}, _from, state) do
    from_guid = elem(Map.fetch(state, :guid), 1)
    dest_guid = elem(Map.fetch(to, :uid), 1)
    node_router(from, to, level-1)
  end
end
