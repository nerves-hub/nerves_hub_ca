defmodule NervesHubCA.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @required_api_opts [:cacertfile, :certfile, :keyfile]

  use Application

  require Logger

  def start(_type, _args) do
    # List all child processes to be supervised
    start_httpc()

    api_opts = Application.get_env(:nerves_hub_ca, :api, [])
    cfssl_opts = Application.get_env(:nerves_hub_ca, :cfssl, [])

    children =
      [
        NervesHubCA.CFSSL.child_spec(cfssl_opts, name: RootCA)
      ] ++ api(api_opts)

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

  defp api(api_opts) do
    keys = Keyword.keys(api_opts)

    if Enum.all?(@required_api_opts, &(&1 in keys)) do
      [
        Plug.Adapters.Cowboy2.child_spec(
          scheme: :https,
          plug: {NervesHubCA.Router, []},
          options: api_opts
        )
      ]
    else
      missing = Enum.reject(@required_api_opts, &(&1 in keys))
      Logger.debug("API Webserver disabled. Missing required https opts #{inspect(missing)}")
      []
    end
  end
end
