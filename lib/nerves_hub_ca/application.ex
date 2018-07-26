defmodule NervesHubCA.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @required_api_opts [:cacerts, :certfile, :keyfile]

  use Application

  alias NervesHubCA.Intermediate.CA

  require Logger

  def start(_type, _args) do
    # List all child processes to be supervised
    start_httpc()

    server_ca_opts = Application.get_env(:nerves_hub_ca, CA.Server, [])

    device_ca_opts = Application.get_env(:nerves_hub_ca, CA.Device, [])

    user_ca_opts = Application.get_env(:nerves_hub_ca, CA.User, [])

    children =
      [
        NervesHubCA.CFSSL.child_spec(server_ca_opts, name: CA.Server),
        NervesHubCA.CFSSL.child_spec(device_ca_opts, name: CA.Device),
        NervesHubCA.CFSSL.child_spec(user_ca_opts, name: CA.User)
      ] ++ api()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NervesHubCA.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_httpc() do
    :inets.start(:httpc, profile: :nerves_hub_ca)

    opts = [
      max_sessions: 8,
      max_keep_alive_length: 4,
      max_pipeline_length: 4,
      keep_alive_timeout: 5_000,
      pipeline_timeout: 5_000
    ]

    :httpc.set_options(opts, :nerves_hub_ca)
  end

  defp api() do
    opts =
      Application.get_env(:nerves_hub_ca, :api, [])
      |> Enum.reject(fn
        {k, v} when is_list(v) ->
          k in @required_api_opts and not Enum.all?(v, &File.exists?/1)

        {k, v} ->
          k in @required_api_opts and not File.exists?(v)
      end)

    keys = Keyword.keys(opts)

    if Enum.all?(@required_api_opts, &(&1 in keys)) do
      Logger.debug("Starting API webserver on #{opts[:port]}")

      ca_certs =
        Keyword.get(opts, :cacerts, [])
        |> NervesHubCA.Utils.cert_files_to_der()

      opts = Keyword.put(opts, :cacerts, ca_certs) |> IO.inspect()

      [
        Plug.Adapters.Cowboy2.child_spec(
          scheme: :https,
          plug: {NervesHubCA.Router, []},
          options: opts
        )
      ]
    else
      missing = Enum.reject(@required_api_opts, &(&1 in keys))
      Logger.debug("API Webserver disabled. Missing required https opts #{inspect(missing)}")
      []
    end
  end
end
