defmodule NervesHubCA.RouterTest do
  use ExUnit.Case
  doctest NervesHubCA.Router

  import NervesHubCA.Utils

  setup_all do
    [
      http_opts: [
        ssl: [
          cacertfile: Path.join(NervesHubCA.Storage.working_dir(), "ca.pem"),
          server_name_indication: 'ca.nerves-hub.org'
        ]
      ]
    ]
  end

  describe "create from CSR" do
    test "devices", context do
      url = url("sign_device_csr")

      key = X509.PrivateKey.new_ec(:secp256r1)

      csr =
        X509.CSR.new(key, "/O=My Org/CN=device-1234")
        |> X509.CSR.to_pem()
        |> Base.encode64()

      params = %{
        csr: csr
      }

      params = Jason.encode!(params)
      assert {:ok, 200, _body} = http_request(:post, url, params, context[:http_opts])
    end

    test "users", context do
      url = url("sign_user_csr")

      key = X509.PrivateKey.new_ec(:secp256r1)

      csr =
        X509.CSR.new(key, "/O=NervesHub/CN=user-1234")
        |> X509.CSR.to_pem()
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

  test "health check returns 200 ok", context do
    url = url("health_check")
    assert {:ok, 200, "ok"} = http_request(:get, url, "", context[:http_opts])
  end

  defp url(endpoint) do
    "https://localhost:8443/" <> endpoint
  end
end
