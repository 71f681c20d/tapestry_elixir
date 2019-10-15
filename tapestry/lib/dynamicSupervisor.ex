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
end
