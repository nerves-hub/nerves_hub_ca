use Mix.Config

config :nerves_hub_ca, NervesHubCA.Repo,
  adapter: Ecto.Adapters.Postgres,
  ssl: false
