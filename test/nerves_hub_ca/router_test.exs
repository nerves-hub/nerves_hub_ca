defmodule NervesHubCA.RouterTest do
  use ExUnit.Case
  doctest NervesHubCA.Router

  import NervesHubCA.Utils

  setup_all do
    server_cert_file = Path.join(NervesHubCA.Storage.working_dir(), "ca-client.pem")
    server_key_file = Path.join(NervesHubCA.Storage.working_dir(), "ca-client-key.pem")

    [
      http_opts: [
        ssl: [
          verify: :verify_peer,
          cacertfile: Path.join(NervesHubCA.Storage.working_dir(), "ca.pem"),
          certfile: server_cert_file,
          keyfile: server_key_file,
          server_name_indication: 'ca.nerves-hub.org'
        ]
      ]
    ]
  end

  describe "create from CSR" do
    test "devices", context do
      url = url("sign_device_csr")

      csr =
        Path.expand("test/fixtures/device.csr")
        |> File.read!()
        |> Base.encode64()

      params = %{
        csr: csr
      }

      params = Jason.encode!(params)
      assert {:ok, 200, _body} = http_request(:post, url, params, context[:http_opts])
    end

    test "users", context do
      url = url("sign_user_csr")

      csr =
        Path.expand("test/fixtures/user.csr")
        |> File.read!()
        |> Base.encode64()

      params = %{
        csr: csr
      }

      params = Jason.encode!(params)
      assert {:ok, 200, _body} = http_request(:post, url, params, context[:http_opts])
    end
  end

  test "can reject fake paths", context do
    url = url("fake")
    assert {:ok, 404, _body} = http_request(:get, url, "", context[:http_opts])
  end

  test "return error is missing client ssl" do
    url = url("newcert")
    assert {:error, _reason} = http_request(:post, url, "")
  end

  test "health check returns 200 ok", context do
    url = url("health_check")
    assert {:ok, 200, "ok"} = http_request(:get, url, "", context[:http_opts])
  end

  defp url(endpoint) do
    "https://localhost:8443/" <> endpoint
  end
end
