defmodule Tapestry.DynamicSupervisor do
  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_child(id_num) do # TODO: change the IDs to hashes
    spec = %{id: id_num, start: {Project2.Server, :start_link, []}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def init(_args) do
    DynamicSupervisor.init(
      strategy: :one_for_one # If you stop, I'll replace you
    )
  end

  def count_children do
    DynamicSupervisor.count_children(__MODULE__)
  end

  def terminate_child(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def create_workers(list, 0) do list end
  def create_workers(list, num) do
    agent = start_child(num)
    case agent do
      {:ok, pid} ->
        newlist = [pid | list]
        num = num - 1
        create_workers(newlist, num)
      other ->
        other
    end
  end

end
