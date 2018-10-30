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

      csr =
        Path.expand("test/fixtures/device-csr.pem")
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
        Path.expand("test/fixtures/user-csr.pem")
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

  test "health check returns 200 ok", context do
    url = url("health_check")
    assert {:ok, 200, "ok"} = http_request(:get, url, "", context[:http_opts])
  end

  defp url(endpoint) do
    "https://localhost:8443/" <> endpoint
  end
end
