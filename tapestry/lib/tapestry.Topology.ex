defmodule Tapestry.Topology do
    def build_topology(worker_list) do
        if worker_list == [] do -> IO.puts 'Error. Topology must have at least 1 node to bootstrap.'

    end

    def search(level, new_node_hash, bouncer) do
        search(level-1, new_node_hash)
        # Pull the level set from this PID's stack, as an ETS datastore match
        level_set =
    end

end
