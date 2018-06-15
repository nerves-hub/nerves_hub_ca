use Mix.Config

config :nerves_hub_ca, :cfssl_defaults,
  ca_config: Path.expand("config/cfssl/ca-config.json"),
  ca_csr: Path.expand("config/cfssl/root-ca-csr.json"),
  storage_adapter: NervesHubCA.Storage.Local

working_dir = Path.join(File.cwd!(), "etc/cfssl")

config :nerves_hub_ca, :api, port: 8443

config :nerves_hub_ca, working_dir: working_dir

if File.dir?(working_dir) do
  config :nerves_hub_ca, :api,
    cacertfile: Path.join(working_dir, "ca.pem"),
    certfile: Path.join(working_dir, "ca-api.pem"),
    keyfile: Path.join(working_dir, "ca-api-key.pem")
end
