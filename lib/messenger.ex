defmodule Messenger do
  def hello do
    Application.get_env(:amnesia, :dir, "NO DIR")
  end

  def start(_type, _agrs) do
    children = [
      {Bandit, plug: Messanger.Router, scheme: :http, options: [port: 8080]}
    ]

    opts = [strategy: :one_for_one, name: Messenger.Supervisor]
    # Mix.Tasks.Amnesia.Create.run(["amnesia.create", "-d", "Database", "--disk"])
    Supervisor.start_link(children, opts)
  end
end
