defmodule Tapestry do

  def start(_type, _args) do
    #args = System.argv()
    args = ["10", "10"]
    case args do
      [num_nodes, _num_requests] ->
        num_nodes = String.to_integer(num_nodes)
        #num_requests = String.to_integer(num_requests)
        Tapestry.DynamicSupervisor.start_link(args)
        [hd | tl] = Tapestry.DynamicSupervisor.start_children(num_nodes, [])
        Enum.map(tl, fn x -> init_tapestry(x, hd) end)
        Tapestry.Server.get_neighbors(hd) #Should have uid 2, 3, 4, 5 as neighbors
      _ ->
        IO.puts 'Invalid arguments please put args: numNodes numRequests'
    end
  end

  def init_tapestry(node, node_in_network) do
    Tapestry.Server.join_from(node, node_in_network)
  end

end
