use Mix.Config

config :nerves_hub_ca, :cfssl_defaults, storage_adapter: NervesHubCA.Storage.S3

config :nerves_hub_ca, :api, port: 8443
