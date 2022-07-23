defmodule Messenger do
  def hello do
    Application.get_env(:amnesia, :dir, "NO DIR")
  end

  def main() do
    # Mix.Tasks.Amnesia.Create.run(["amnesia.create", "-d", "Database", "--disk"])
  end
end
