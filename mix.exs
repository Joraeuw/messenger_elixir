defmodule Messenger.MixProject do
  use Mix.Project

  def project do
    [
      app: :messenger,
      version: "0.1.0",
      elixir: "~> 1.14-dev",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Messenger, []},
      extra_applications: [:logger, :crypto, :plug]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amnesia, git: "https://github.com/meh/amnesia.git"},
      {:bandit, ">= 0.5.0"},
      {:uuid, "~> 1.1"},
      {:json, "~> 1.4"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
