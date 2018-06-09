defmodule NervesHubCA.InitHelper do
  @tmp Path.expand("test/tmp")

  alias NervesHubCA.CFSSL

  def start do
    File.rm_rf(@tmp)
    File.mkdir_p(@tmp)

    CFSSL.wait(RootCA)
    init_ca(@tmp)
    init_api(@tmp)
  end

  def init_ca(path) do
    # Create the root ca certificates
    ca_params = %{
      hosts: [""],
      names: [%{O: "NervesHub", OU: "NervesHub Certificate Authority"}]
    }

    {:ok, result} = CFSSL.init_ca(RootCA, ca_params)

    ca = Map.get(result, "certificate")
    ca_key = Map.get(result, "private_key")

    # Save the root certs
    path = Path.expand(path)
    File.mkdir(path)

    ca_file = Path.join(path, "ca.pem")
    File.write!(ca_file, ca)

    ca_key_file = Path.join(path, "ca-key.pem")
    File.write!(ca_key_file, ca_key)

    cfssl_conf =
      Application.get_env(:nerves_hub_ca, :cfssl, [])
      |> Keyword.put(:ca, ca_file)
      |> Keyword.put(:ca_key, ca_key_file)

    Application.put_env(:nerves_hub_ca, :cfssl, cfssl_conf)
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
    File.mkdir(path)

    cert_file = Path.join(path, "ca-api.pem")
    File.write!(cert_file, cert)

    key_file = Path.join(path, "ca-api-key.pem")
    File.write!(key_file, key)

    ca_file =
      Application.get_env(:nerves_hub_ca, :cfssl)
      |> Keyword.get(:ca)

    api_conf =
      Application.get_env(:nerves_hub_ca, :api, [])
      |> Keyword.put(:cacertfile, ca_file)
      |> Keyword.put(:certfile, cert_file)
      |> Keyword.put(:keyfile, key_file)

    Application.put_env(:nerves_hub_ca, :api, api_conf)
    restart()
  end

  def tmp() do
    @tmp
  end

  defp restart() do
    Application.stop(:nerves_hub_ca)
    Application.start(:nerves_hub_ca)
    CFSSL.wait(RootCA)
  end
end
