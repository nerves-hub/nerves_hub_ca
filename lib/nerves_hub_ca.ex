defmodule NervesHubCA do
  alias NervesHubCA.CFSSL
  alias NervesHubCA.Intermediate.CA

  @doc """
  Create a new certificate for a device.

  The supplied serial number will be stored
  in the Organization of the Distinguished Name.

  Parameters:
    `serial`: The manufacturer serial number of the device
  """
  @spec create_device_certificate(binary) :: CFSSL.result()
  def create_device_certificate(serial) do
    params = %{
      request: %{
        hosts: [""],
        names: [%{O: serial}],
        CN: "NervesHub Device Certificate"
      },
      profile: "device"
    }

    CFSSL.newcert(CA.Device, params)
  end

  @doc """
  Sign a device certificate.

  The supplied certificate will contain the serial
  number in the organization field.

  See the document:
  Generating and signing CSRs.md

  Parameters:
    `csr`: The binary certificate signing request
  """
  @spec sign_device_csr(binary) :: CFSSL.result()
  def sign_device_csr(csr) do
    ca_opts = Application.get_env(:nerves_hub_ca, CA.Device, [])
    ca_cert = ca_opts[:ca]
    ca_key = ca_opts[:ca_key]

    config = Path.join(config_dir(), "ca-config.json")
    csr_path = Plug.Upload.random_file!("csr")
    File.write!(csr_path, csr)

    CFSSL.sign(csr_path, ca_cert, ca_key, config, "device")
  end

  @doc """
  Create a new certificate for a user.

  The supplied username will be stored
  in the Organization of the Distinguished Name.

  Parameters:
    `username`: The username for the certificate
  """
  @spec create_user_certificate(binary) :: CFSSL.result()
  def create_user_certificate(username) do
    params = %{
      request: %{
        hosts: [""],
        names: [%{O: username}],
        CN: "NervesHub User Certificate"
      },
      profile: "user"
    }

    CFSSL.newcert(CA.User, params)
  end

  @doc """
  Sign a user certificate.

  The supplied certificate will contain the usrrname
  in the Organization of the Distinguished Name.

  See the document:
  Generating and signing CSRs.md

  Parameters:
    `csr`: The binary certificate signing request
  """
  @spec sign_user_csr(binary) :: CFSSL.result()
  def sign_user_csr(csr) do
    ca_opts = Application.get_env(:nerves_hub_ca, CA.User, [])
    ca_cert = ca_opts[:ca]
    ca_key = ca_opts[:ca_key]

    config = Path.join(config_dir(), "ca-config.json")
    csr_path = Plug.Upload.random_file!("csr")
    File.write!(csr_path, csr)

    CFSSL.sign(csr_path, ca_cert, ca_key, config, "user")
  end

  @doc """
  Create a new certificate for a server.

  Parameters:
    `host`: The hostname for the server
  """
  @spec create_server_certificate(binary) :: CFSSL.result()
  def create_server_certificate(host) do
    params = %{
      request: %{
        hosts: [host],
        names: [%{O: "NervesHub"}],
        CN: host
      },
      profile: "server"
    }

    CFSSL.newcert(CA.Server, params)
  end

  defp config_dir do
    :code.priv_dir(:nerves_hub_ca)
    |> to_string()
    |> Path.join("cfssl")
  end
end
