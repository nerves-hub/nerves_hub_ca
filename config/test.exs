use Mix.Config

working_dir = Path.expand("test/tmp")

config :nerves_hub_ca, working_dir: working_dir

config :nerves_hub_ca, :cfssl_defaults,
  ca_config: Path.expand("config/cfssl/ca-config.json"),
  ca_csr: Path.expand("config/cfssl/root-ca-csr.json"),
  ca: Path.join(working_dir, "ca.pem"),
  ca_key: Path.join(working_dir, "ca-key.pem")

config :nerves_hub_ca, :api,
  port: 4443,
  verify: :verify_peer,
  fail_if_no_peer_cert: true,
  cacertfile: Path.join(working_dir, "ca.pem"),
  certfile: Path.join(working_dir, "ca-api.pem"),
  keyfile: Path.join(working_dir, "ca-api-key.pem")

config :logger, level: :error
