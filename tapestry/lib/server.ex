defmodule Tapestry.Server do
  use GenServer

  #init
  def start_link(guid) do
      GenServer.start_link(__MODULE__, %{guid: "#{guid}", neighbors: {{ %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{} }, {  %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{} }, {  %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{} }, { %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{}, %{} }} }) #number of levels should match length of uid
  end

  def init(state) do
    {:ok, state}
  end

  #join
  def join([], called_list, _from) do
    called_list
  end

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

  def join_from(from, to) do
    pid_from = elem(Map.fetch(from, :pid), 1)
    GenServer.call(pid_from, {:join_from, from, to})
  end

  def handle_call({:join_from, from, to}, _from, state) do
    res = join([to], [], from)
    state = add_list_to_dht(res, state)
    {:reply, state, state}
  end

  def get_neighbors(node) do
    pid = elem(Map.fetch(node, :pid), 1)
    GenServer.call(pid, :get_neighbors)
  end

  def handle_call(:get_neighbors, _from, state) do
    neighbors = elem(Map.fetch(state, :neighbors), 1)
    {:reply, neighbors, state}
  end

  def suffix_distance(guid_from, guid_to), do: suffix_distance(guid_from, guid_to, 0) # computes the suffix distance metric of 2 strings
  def suffix_distance(hash, "", level), do: level
  def suffix_distance("", hash, level), do: level
  def suffix_distance(guid_from, guid_to, level) do
    {hf,tf} = String.next_grapheme(guid_from)
    {ht,tt} = String.next_grapheme(guid_to)
    cond do
      hf == ht -> suffix_distance(tf,tt,level+1)
      hf != ht -> level+1
    end
  end

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
    index = Enum.random(0..15) #TODO fix
    this_level = Tuple.delete_at(this_level, index)
    this_level = Tuple.insert_at(this_level, index, node)
    dht = Tuple.delete_at(dht, level)
    dht = Tuple.insert_at(dht, level, this_level)
    Map.put(state, :neighbors, dht)
  end

  def flattened_dht(state) do
    dht = elem(Map.fetch(state, :neighbors), 1)
    list_of_tuples = Tuple.to_list(dht)
    List.flatten(Enum.map(list_of_tuples, fn x -> Tuple.to_list(x) end))
  end
end
