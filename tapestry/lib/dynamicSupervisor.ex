defmodule Tapestry.DynamicSupervisor do
  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    DynamicSupervisor.init(
      strategy: :one_for_one
    )
  end

  def start_child(id_num) do
    spec = %{id: id_num, start: {Tapestry.Server, :start_link, []}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def start_children(0, list) do
    list
  end
  def start_children(num_children, list) do
    uuid = num_children #TODO change to generate uid
    {:ok, pid} = start_child(uuid)
    list = [%{uid: uuid, pid: pid} | list]
    IO.puts 'child created'
    start_children(num_children - 1, list)
  end
end
