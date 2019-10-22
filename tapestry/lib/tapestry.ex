defmodule Tapestry do

  def start(_type, _args) do
    #args = System.argv()
    args = ["10", "10"]
    case args do
      [num_nodes, num_requests] ->
        num_nodes = String.to_integer(num_nodes)
        num_requests = String.to_integer(num_requests)
        Tapestry.DynamicSupervisor.start_link(args)
        nodes = Tapestry.DynamicSupervisor.start_children(num_nodes, [])
        [hd | tl] = nodes
        Enum.map(tl, fn x -> init_tapestry(x, hd) end)
        maxlist = Enum.map(nodes, fn x -> do_message(x, nodes, num_requests, 0) end)
        IO.puts Integer.to_string(Enum.max(maxlist))
      _ ->
        IO.puts 'Invalid arguments please put args: numNodes numRequests'
    end
  end

  def do_message(from_node, node_list, 0, max) do max end
  def do_message(from_node, node_list, num_requests_remaining, max) do
    from_str = elem(Map.fetch(from_node, :uid), 1)
    to_str = elem(Map.fetch(Enum.random(node_list), :uid), 1)
    num_hops = Tapestry.Server.suffix_distance(from_str, to_str) #TODO
    cond do
      num_hops > max ->
        do_message(from_node, node_list, num_requests_remaining-1, num_hops)
      true ->
        do_message(from_node, node_list, num_requests_remaining-1, max)
    end
  end

  def init_tapestry(node, node_in_network) do
    Tapestry.Server.join_from(node, node_in_network)
  end

end
