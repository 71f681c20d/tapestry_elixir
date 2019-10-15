defmodule Tapestry do

  def start(_type, _args) do
    args = System.argv()
    case args do
      [num_nodes, num_requests] ->
        Tapestry.DynamicSupervisor.start_link(args)
        Tapestry.DynamicSupervisor.start_child(0) #0 is id_num of server
      _ ->
        IO.puts 'Invalid arguments please put args: numNodes numRequests'
    end
  end

end
