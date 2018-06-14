# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :nerves_hub_ca, :cfssl,
  ca_config: Path.expand("config/cfssl/ca-config.json"),
  root_ca_csr: Path.expand("config/cfssl/root-ca-csr.json"),
  port: 8888,
  address: "127.0.0.1"

import_config "#{Mix.env()}.exs"
