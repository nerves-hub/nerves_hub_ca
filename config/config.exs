# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :nerves_hub_ca,
  ecto_repos: [NervesHubCA.Repo]

alias NervesHubCA.Intermediate.CA

working_dir =
  case Mix.env() do
    :prod -> "/etc/ssl"
    :dev -> Path.expand("../etc/ssl", __DIR__)
    :test -> Path.expand("../test/tmp", __DIR__)
  end

working_dir = System.get_env("NERVES_HUB_CA_DIR") || working_dir

config :nerves_hub_ca, working_dir: working_dir

config :nerves_hub_ca, :cfssl_defaults,
  ca: Path.join(working_dir, "root-ca.pem"),
  ca_key: Path.join(working_dir, "ca-key.pem")

config :nerves_hub_ca, :api,
  otp_app: :nerves_hub_ca,
  port: 8443,
  cacertfile: Path.join(working_dir, "ca.pem"),
  certfile: Path.join(working_dir, "ca.nerves-hub.org.pem"),
  keyfile: Path.join(working_dir, "ca.nerves-hub.org-key.pem")

config :nerves_hub_ca, CA.User,
  ca: Path.join(working_dir, "user-root-ca.pem"),
  ca_key: Path.join(working_dir, "user-root-ca-key.pem")

import_config "#{Mix.env()}.exs"
