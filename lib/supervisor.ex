defmodule Messenger.Supervisor do
  use Supervisor
  alias Messenger
  alias Storage

  def start_link(init_arg \\ []) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # Mix.Tasks.Amnesia.Create.run(["amnesia.create", "-d", "Database", "--disk"])

    children = [
      # {Server, []},
      # {, []}
      # {Messenger, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
