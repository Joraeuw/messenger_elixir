defmodule Messenger.Supervisor do
  use Supervisor
  alias Messenger
  alias Storage

  def start_link(init_arg \\ []) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    Supervisor.init([], strategy: :one_for_one)
  end
end
