defmodule Tapestry do

  def start(_type, _args) do
    #args = System.argv()
    :observer.start
    args = ["100", "3"]
    case args do
      [num_nodes, num_requests] ->
        num_nodes = String.to_integer(num_nodes)
        num_requests = String.to_integer(num_requests)
        Tapestry.DynamicSupervisor.start_link(args)
        listener = elem(Tapestry.DynamicSupervisor.start_listener(num_nodes * num_requests), 1)
        nodes = Tapestry.DynamicSupervisor.start_children(num_nodes, [])
        [hd | tl] = nodes
        Enum.map(tl, fn x -> init_tapestry(x, hd) end)                                            # Pick the first node to join everyone else
        Enum.map(nodes, fn x -> do_message(x, nodes, num_requests, listener) end)                 # Send a message from eavry other node
        loop(num_nodes + 1) #TODO Busy wait not ideal
      _ ->
        IO.puts 'Invalid arguments please put args: numNodes numRequests'
    end
  end

  def do_message(_from_node, _node_list, 0, _listener_pid) do :done end
  def do_message(from_node, node_list, num_requests_remaining, listener_pid) do
    to_node = Enum.random(node_list -- [from_node])                                               # Send to a rando per
    Tapestry.Server.send_message(from_node, to_node, listener_pid)                                # Ruote message to peer
    IO.inspect(Enum.join(["Initiating from", elem(Map.fetch(from_node, :uid),1), "to", elem(Map.fetch(to_node, :uid),1)], " "))
    do_message(from_node, node_list, num_requests_remaining-1, listener_pid)                       # Send the next message
  end

  def init_tapestry(node, node_in_network) do
    Tapestry.Server.join_from(node, node_in_network)
  end

  def loop(num_nodes) do
    map = Tapestry.DynamicSupervisor.count_children
    num_active = elem(Map.fetch(map, :active), 1)
    if (num_active == num_nodes) do
      loop(num_nodes)
    end
  end
end
