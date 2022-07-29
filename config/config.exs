import Config

config :amnesia,
  dir: "../db",
  # 1 minute | :no_limit
  edit_after: 1 * 60 * 1000
