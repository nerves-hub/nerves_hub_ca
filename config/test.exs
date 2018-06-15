use Mix.Config

config :nerves_hub_ca, working_dir: Path.expand("test/tmp")

config :nerves_hub_ca, :cfssl_defaults,
  ca_config: Path.expand("config/cfssl/ca-config.json"),
  ca_csr: Path.expand("config/cfssl/root-ca-csr.json"),
  storage_adapter: NervesHubCA.Storage.Local

config :nerves_hub_ca, :api,
  port: 8443,
  verify: :verify_peer,
  fail_if_no_peer_cert: true

config :logger, level: :info
