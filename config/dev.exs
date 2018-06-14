use Mix.Config

working_dir = Path.join(File.cwd!(), "etc/cfssl")

config :nerves_hub_ca, :api, port: 8443

config :nerves_hub_ca, working_dir: working_dir

if File.dir?(working_dir) do
  config :nerves_hub_ca, :api,
    cacertfile: Path.join(working_dir, "ca.pem"),
    certfile: Path.join(working_dir, "ca-api.pem"),
    keyfile: Path.join(working_dir, "ca-api-key.pem")
end
