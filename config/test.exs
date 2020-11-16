import Config

config :nerves_hub_ca, NervesHubCA.Repo,
  adapter: Ecto.Adapters.Postgres,
  ssl: false,
  pool: Ecto.Adapters.SQL.Sandbox

config :logger,
  level: :warn
