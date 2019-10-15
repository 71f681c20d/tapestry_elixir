defmodule Tapestry do

  def start(_type, _args) do
    args = System.argv()
    case args do
      [num_nodes, num_requests] ->
        num_nodes = String.to_integer(num_nodes)
        num_requests = String.to_integer(num_requests)
        Tapestry.DynamicSupervisor.start_link(args)
        Tapestry.DynamicSupervisor.start_children(num_nodes, [])
      _ ->
        IO.puts 'Invalid arguments please put args: numNodes numRequests'
    end
  end

end
