defmodule NervesHubCA.InitHelper do
  alias NervesHubCA.CFSSL

  def start do
    path = NervesHubCA.working_dir()
    File.rm_rf(path)
    File.mkdir_p(path)

    CFSSL.wait(RootCA)
    init_ca(path)
    init_api(path)
  end

  def init_ca(path) do
    # Create the root ca certificates
    csr =
      Application.get_env(:nerves_hub_ca, :cfssl)
      |> Keyword.get(:root_ca_csr)
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
        names: [%{O: "nerves-hub"}],
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

  defp restart() do
    Application.stop(:nerves_hub_ca)
    Application.start(:nerves_hub_ca)
    CFSSL.wait(RootCA)
  end
end
