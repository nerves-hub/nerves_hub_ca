import Config

working_dir = "/etc/ssl"

host = System.fetch_env!("HOST")

config :nerves_hub_ca, :api,
  otp_app: :nerves_hub_ca,
  port: 8443,
  cacertfile: Path.join(working_dir, "ca.pem"),
  certfile: Path.join(working_dir, "#{host}.pem"),
  keyfile: Path.join(working_dir, "#{host}-key.pem")
