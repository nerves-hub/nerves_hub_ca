use Mix.Config

config :nerves_hub_ca, :api, port: 8443

ca_cert_store = Path.join(File.cwd!(), "ssl")

if File.dir?(ca_cert_store) do
  ca_cert_store = Path.expand(ca_cert_store)

  config :nerves_hub_ca, :api,
    cacertfile: Path.join(ca_cert_store, "ca.pem"),
    certfile: Path.join(ca_cert_store, "ca-api.pem"),
    keyfile: Path.join(ca_cert_store, "ca-api-key.pem")

  config :nerves_hub_ca, :cfssl,
    ca: Path.join(ca_cert_store, "ca.pem"),
    ca_key: Path.join(ca_cert_store, "ca-key.pem")
end
