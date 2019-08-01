use Mix.Config

config :nerves_hub_ca, NervesHubCA.Repo, adapter: Ecto.Adapters.Postgres

working_dir = "/etc/ssl"

config :nerves_hub_ca, :api,
  otp_app: :nerves_hub_ca,
  port: 8443,
  cacertfile: Path.join(working_dir, "ca.pem"),
  certfile: Path.join(working_dir, "${HOST}.pem"),
  keyfile: Path.join(working_dir, "${HOST}-key.pem")
