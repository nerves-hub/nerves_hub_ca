defmodule NervesHubCA.RouterTest do
  use ExUnit.Case
  doctest NervesHubCA.Router

  alias NervesHubCA.CFSSL
  import NervesHubCA.Utils

  setup_all do
    params = %{
      request: %{
        hosts: ["www.nerves-hub.org"],
        names: [%{O: "nerves-hub"}],
        CN: "www.nerves-hub.org"
      }
    }

    {:ok, result} = CFSSL.newcert(RootCA, params)

    server_cert = Map.get(result, "certificate")
    server_key = Map.get(result, "private_key")

    server_cert_file = Path.join(NervesHubCA.working_dir(), "server.pem")
    server_key_file = Path.join(NervesHubCA.working_dir(), "server-key.pem")

    File.write!(server_cert_file, server_cert)
    File.write!(server_key_file, server_key)

    [
      http_opts: [
        ssl: [
          verify: :verify_peer,
          cacertfile: CFSSL.ca_cert(RootCA),
          certfile: server_cert_file,
          keyfile: server_key_file,
          server_name_indication: 'ca.nerves-hub.org'
        ]
      ],
      params: params
    ]
  end

  test "can create device certificates", context do
    url = url("create_device_certificate")

    params = %{
      serial: "12345"
    }

    params = Jason.encode!(params)
    assert {:ok, 200, _body} = http_request(:post, url, params, context[:http_opts])
  end

  test "can match cfssl paths", context do
    url = url("newcert")
    params = Jason.encode!(context[:params])
    assert {:ok, 200, _body} = http_request(:post, url, params, context[:http_opts])
  end

  test "can reject fake paths", context do
    url = url("fake")
    assert {:ok, 404, _body} = http_request(:get, url, "", context[:http_opts])
  end

  test "return error is missing client ssl" do
    url = url("newcert")
    assert {:error, _reason} = http_request(:post, url, "")
  end

  defp url(endpoint) do
    "https://localhost:8443/" <> endpoint
  end
end
