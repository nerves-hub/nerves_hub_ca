defmodule NervesHubCA.Router do
  @moduledoc """

  Route: /device
    Method: POST
    Parameters:
      `serial`: The manufacture serial number

    Response Parameters
      `certificate`: The certificate
      `certificate_request`: The certificate signing request
      `private_key`: The private key
      `sums`: Certificate checksums 

  Route: *
    All other matches are attempted directly against the cfssl instance

  For more information on the available api endpoints
  please refer to the CFSSL api docs

  https://github.com/cloudflare/cfssl/tree/master/doc/api
  """

  use Plug.Router

  @plug_parsers_opts [
    parsers: [:json],
    pass: ["*/*"],
    length: 160_000_000,
    json_decoder: Jason
  ]

  plug(:match)
  plug(:dispatch)

  get "health_check" do
    send_resp(conn, 200, "ok")
  end

  post "create_device_certificate" do
    opts = Plug.Parsers.init(@plug_parsers_opts)
    conn = Plug.Parsers.call(conn, opts)

    case Map.get(conn.body_params, "serial") do
      nil ->
        send_resp(conn, 400, "Missing parameter: serial")

      serial ->
        {:ok, result} = NervesHubCA.create_device_certificate(serial)
        send_resp(conn, 200, Jason.encode!(result))
    end
  end

  post "create_user_certificate" do
    opts = Plug.Parsers.init(@plug_parsers_opts)
    conn = Plug.Parsers.call(conn, opts)

    case Map.get(conn.body_params, "username") do
      nil ->
        send_resp(conn, 400, "Missing parameter: username")

      username ->
        {:ok, result} = NervesHubCA.create_user_certificate(username)
        send_resp(conn, 200, Jason.encode!(result))
    end
  end

  post "create_server_certificate" do
    opts = Plug.Parsers.init(@plug_parsers_opts)
    conn = Plug.Parsers.call(conn, opts)

    case Map.get(conn.body_params, "hostname") do
      nil ->
        send_resp(conn, 400, "Missing parameter: hostname")

      hostname ->
        {:ok, result} = NervesHubCA.create_server_certificate(hostname)
        send_resp(conn, 200, Jason.encode!(result))
    end
  end

  match _ do
    method = conn.method |> String.downcase() |> String.to_atom()
    path = conn.path_info |> List.last()
    {:ok, params, conn} = Plug.Conn.read_body(conn)

    resp = NervesHubCA.CFSSL.request(RootCA, method, path, params)

    resp(conn, resp)
  end

  defp resp(conn, resp) do
    {status, body} =
      case resp do
        {:ok, status, body} -> {status, body}
        {:error, reason} -> {500, inspect(reason)}
      end

    send_resp(conn, status, body)
  end
end
