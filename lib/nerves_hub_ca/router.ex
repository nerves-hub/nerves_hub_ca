defmodule NervesHubCA.Router do
  @moduledoc """

  Route: /health_check
    Method: GET
    Response: 200 OK
      
  Route: /sign_device_csr
    Method: POST
    Parameters:
      `csr`: Binary certificate signing request for the device

    Response Parameters
      `cert`: The certificate pem
      `issuer`: The issuer pem
      `error`: Present if any error occurred during processing

  Route: /sign_user_csr
    Method: POST
    Parameters:
      `csr`: Binary certificate signing request for the device

    Response Parameters
      `cert`: The certificate pem
      `issuer`: The issuer pem
      `error`: Present if any error occurred during processing
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

  post "sign_device_csr" do
    opts = Plug.Parsers.init(@plug_parsers_opts)
    conn = Plug.Parsers.call(conn, opts)

    case Map.get(conn.body_params, "csr") do
      nil ->
        send_resp(conn, 400, "Missing parameter: csr")

      csr ->
        csr = Base.decode64!(csr) |> X509.CSR.from_pem!()

        case NervesHubCA.sign_device_csr(csr) do
          {:ok, result} ->
            send_resp(conn, 200, Jason.encode!(result))

          {:error, error} ->
            resp = encode_error(error)
            send_resp(conn, 400, resp)
        end
    end
  end

  post "sign_user_csr" do
    opts = Plug.Parsers.init(@plug_parsers_opts)
    conn = Plug.Parsers.call(conn, opts)

    case Map.get(conn.body_params, "csr") do
      nil ->
        send_resp(conn, 400, "Missing parameter: csr")

      csr ->
        csr = Base.decode64!(csr) |> X509.CSR.from_pem!()

        case NervesHubCA.sign_user_csr(csr) do
          {:ok, result} ->
            send_resp(conn, 200, Jason.encode!(result))

          {:error, error} ->
            resp = encode_error(error)
            send_resp(conn, 400, resp)
        end
    end
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  defp encode_error(%{erorrs: errors}) do
    Enum.reduce(errors, %{}, fn {field, {reason, _}}, acc ->
      Map.put(acc, field, reason)
    end)
    |> Jason.encode!()
  end
end
