defmodule NervesHubCA.InitHelper do
  alias NervesHubCA.CFSSL

  def start do
    Application.ensure_all_started(:nerves_hub_ca)

    path = NervesHubCA.Storage.working_dir()
    File.rm_rf(path)
    File.mkdir_p(path)

    CFSSL.wait(RootCA)
    init_ca(path)
    init_api(path)
    init_server(path)
  end

  def init_ca(path) do
    # Create the root ca certificates
    csr =
      Application.get_env(:nerves_hub_ca, :cfssl_defaults)
      |> Keyword.get(:ca_csr)
      |> File.read!()
      |> Jason.decode!()

    {:ok, result} = CFSSL.init_ca(RootCA, csr)

    ca = Map.get(result, "certificate")
    ca_key = Map.get(result, "private_key")

    # Save the root certs
    path = Path.expand(path)
    File.mkdir_p(path)

    ca_file = Path.join(path, "ca.pem")
    File.write!(ca_file, ca)

    ca_key_file = Path.join(path, "ca-key.pem")
    File.write!(ca_key_file, ca_key)

    restart()
  end

  def init_api(path) do
    # Create the API server certificates
    server_params = %{
      request: %{
        hosts: ["ca.nerves-hub.org"],
        names: [%{O: "NervesHub"}],
        CN: "ca.nerves-hub.org"
      }
    }

    {:ok, result} = CFSSL.newcert(RootCA, server_params)

    cert = Map.get(result, "certificate")
    key = Map.get(result, "private_key")

    # Save the api certs
    path = Path.expand(path)
    File.mkdir_p(path)

    cert_file = Path.join(path, "ca-api.pem")
    File.write!(cert_file, cert)

    key_file = Path.join(path, "ca-api-key.pem")
    File.write!(key_file, key)

    ca_file = Path.join(path, "ca.pem")

    api_conf =
      Application.get_env(:nerves_hub_ca, :api, [])
      |> Keyword.put(:cacertfile, ca_file)
      |> Keyword.put(:certfile, cert_file)
      |> Keyword.put(:keyfile, key_file)

    Application.put_env(:nerves_hub_ca, :api, api_conf)
    restart()
  end

  def init_server(path) do
    params = %{
      request: %{
        hosts: ["device.nerves-hub.org"],
        names: [%{O: "NervesHub"}],
        CN: "device.nerves-hub.org"
      }
    }

    {:ok, result} = CFSSL.newcert(RootCA, params)

    server_cert = Map.get(result, "certificate")
    server_key = Map.get(result, "private_key")

    server_cert_file = Path.join(path, "server.pem")
    server_key_file = Path.join(path, "server-key.pem")

    File.write!(server_cert_file, server_cert)
    File.write!(server_key_file, server_key)
  end

  defp restart() do
    Application.stop(:nerves_hub_ca)
    Application.start(:nerves_hub_ca)
    CFSSL.wait(RootCA)
  end
end
