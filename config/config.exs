# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

alias NervesHubCA.Intermediate.CA

working_dir =
  case Mix.env() do
    :prod -> "/etc/cfssl"
    :dev -> Path.expand("../etc/cfssl", __DIR__)
    :test -> Path.expand("../test/tmp", __DIR__)
  end

working_dir = System.get_env("NERVES_HUB_CA_DIR") || working_dir

config :nerves_hub_ca, working_dir: working_dir

config :nerves_hub_ca, :cfssl_defaults,
  ca_config: Path.expand("priv/cfssl/ca-config.json"),
  ca_csr: Path.expand("priv/cfssl/root-ca-csr.json"),
  ca: Path.join(working_dir, "root-ca.pem"),
  ca_key: Path.join(working_dir, "ca-key.pem")

config :nerves_hub_ca, :api,
  otp_app: :nerves_hub_ca,
  port: 8443,
  verify: :verify_peer,
  fail_if_no_peer_cert: true,
  cacertfile: Path.join(working_dir, "ca.pem"),
  certfile: Path.join(working_dir, "ca.nerves-hub.org.pem"),
  keyfile: Path.join(working_dir, "ca.nerves-hub.org-key.pem")

config :nerves_hub_ca, CA.Server,
  port: 8000,
  ca: Path.join(working_dir, "intermediate-server-ca.pem"),
  ca_key: Path.join(working_dir, "intermediate-server-ca-key.pem")

config :nerves_hub_ca, CA.Device,
  port: 8001,
  ca: Path.join(working_dir, "intermediate-device-ca.pem"),
  ca_key: Path.join(working_dir, "intermediate-device-ca-key.pem")

config :nerves_hub_ca, CA.User,
  port: 8002,
  ca: Path.join(working_dir, "intermediate-user-ca.pem"),
  ca_key: Path.join(working_dir, "intermediate-user-ca-key.pem")
