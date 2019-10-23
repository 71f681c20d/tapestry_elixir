defmodule Tapestry.Server do
  use GenServer

  #init
  def start_link(guid) do
      GenServer.start_link(__MODULE__, %{guid: "#{guid}", neighbors: {{ %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{} }, {  %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{} }, {  %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{} }, { %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{} }} }) #number of levels should match length of uid
  end

  def init(state) do
    {:ok, state}
  end

  #-----------------------------------------------------------------------
  # Join
  #-----------------------------------------------------------------------

  # Join a node to the network, get a list of all nodes in network
  def join([], called_list, _from) do called_list end
  def join(to_call_list, called_list, from) do
    [hd | tl] = to_call_list
    pid = elem(Map.fetch(hd, :pid), 1)
    res = GenServer.call(pid, {:join, from})
    called_list = [hd | called_list]
    lst = Enum.uniq(List.flatten([tl | res]))
    lst2 = Enum.filter(lst, fn el -> !Enum.member?(called_list, el) end)
    lst2 = Enum.filter(lst2, fn x -> x != %{} end)
    join(lst2, called_list, from)
  end

  def handle_call({:join, from_data}, _from, state) do
    neighbors = flattened_dht(state)
    state = add_to_dht(from_data, state)
    {:reply, neighbors, state}
  end

  # Use join_from to initiate node to attempt to join network
  def join_from(from, to) do
    pid_from = elem(Map.fetch(from, :pid), 1)
    GenServer.call(pid_from, {:join_from, from, to})
  end

  def handle_call({:join_from, from, to}, _from, state) do
    res = join([to], [], from)
    state = add_list_to_dht(res, state)
    {:reply, state, state}
  end

  # Computes the suffix distance metric of 2 strings
  def suffix_distance(guid_from, guid_to), do: suffix_distance(guid_from, guid_to, 0)
  def suffix_distance(_hash, "", level), do: level
  def suffix_distance("", _hash, level), do: level
  def suffix_distance(guid_from, guid_to, level) do
    {hf,tf} = String.next_grapheme(guid_from)
    {ht,tt} = String.next_grapheme(guid_to)
    cond do
      hf == ht -> suffix_distance(tf,tt,level+1)
      hf != ht -> level+1
    end
  end

  # Adds neighbor to the dht at the proper level, its column value is equal to char at level
  def add_list_to_dht([], state) do state end
  def add_list_to_dht([hd | tl], state) do
    new_state = add_to_dht(hd, state)
    add_list_to_dht(tl, new_state)
  end
  def add_to_dht(node, state) do
    my_name = elem(Map.fetch(state, :guid), 1)
    node_name = elem(Map.fetch(node, :uid), 1)
    dht = elem(Map.fetch(state, :neighbors), 1)
    level = suffix_distance(my_name, node_name) - 1
    this_level = elem(dht, level)
    index =  elem(Integer.parse(String.at(node_name, level), 16), 0)
    this_level = Tuple.delete_at(this_level, index)
    this_level = Tuple.insert_at(this_level, index, node)
    dht = Tuple.delete_at(dht, level)
    dht = Tuple.insert_at(dht, level, this_level)
    Map.put(state, :neighbors, dht)
  end

  #Flatten the dht into a list for transmission
  def flattened_dht(state) do
    dht = elem(Map.fetch(state, :neighbors), 1)
    list_of_tuples = Tuple.to_list(dht)
    List.flatten(Enum.map(list_of_tuples, fn x -> Tuple.to_list(x) end))
  end

  #-----------------------------------------------------------------------
  #Routing
  #-----------------------------------------------------------------------

  # Determine the nodes that should be called with the message
  # Wraps choose_best node
  def find_next_node(-1, _state, _to_uid) do
    IO.puts 'ERROR'
    :error_no_next_node_found
  end
  def find_next_node(current_level, state, to_uid) do
    dht = elem(Map.fetch(state, :neighbors), 1)
    this_level = Tuple.to_list(elem(dht, current_level))
    this_level = Enum.filter(this_level, fn x -> x != %{} end)
    case this_level do
      [] ->
        find_next_node(current_level-1, state, to_uid)
      _ ->
        choose_best_node(this_level, to_uid)
    end
  end

  #Determines the best nodes to call at A specific level
  def choose_best_node(list, to_uid) do choose_best_node(list, to_uid, 0, []) end
  def choose_best_node([], _to_uid, _best_dist, best_node) do best_node end
  def choose_best_node([hd | tl], to_uid, best_dist, best_node) do
    hd_name = elem(Map.fetch(hd, :uid), 1)
    dist = suffix_distance(hd_name, to_uid)
    cond do
      dist > best_dist ->
        #More letters match
        choose_best_node(tl, to_uid, dist, [hd])
      dist < best_dist ->
        choose_best_node(tl, to_uid, best_dist, best_node)
      dist == best_dist ->
        choose_best_node(tl, to_uid, best_dist, [ hd | best_node])
    end
  end

  # Handle sending of message
  def send_message(from, to, listener_pid) do
    from_pid = elem(Map.fetch(from, :pid), 1)
    GenServer.cast(from_pid, {:msg, to, 0, listener_pid})   # Start off with 0 jumps
  end

  def handle_cast({:msg, to, jumps, og_pid}, state) do
    my_name = elem(Map.fetch(state, :guid), 1)
    to_name = elem(Map.fetch(to, :uid), 1)
    cond do
      my_name == to_name ->                       # If you are already at the terminating node
        GenServer.cast(og_pid, {:found, jumps, to_name})
        {:noreply, state}
      true ->
        level = suffix_distance(my_name, to_name) - 1
        next_node_list = Enum.filter(find_next_node(level, state, to_name), fn x -> x != [] end)
        next_node_pid = elem(Map.fetch(Enum.random(next_node_list), :pid), 1) # TODO Alex please check this, cant cast to every node on level as will create excess traffic and the end node will receive message multiple times
        GenServer.cast(next_node_pid, {:msg, to, jumps+1, og_pid})
        {:noreply, state} # send response
    end
  end
end
