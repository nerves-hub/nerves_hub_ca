# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :nerves_hub_ca, RootCA,
  port: 8888,
  address: "127.0.0.1"

config :nerves_hub_ca, NervesHubCA.Storage.S3, bucket: "nerves-hub-ca"

config :ex_aws,
  s3_host: System.get_env("S3_HOST"),
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role],
  region: System.get_env("AWS_REGION"),
  json_codec: Jason

import_config "#{Mix.env()}.exs"
