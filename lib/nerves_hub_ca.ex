defmodule NervesHubCA do
  alias NervesHubCA.CFSSL
  alias NervesHubCA.Intermediate.CA

  @doc """
  Get certificate information
   parameters:
    `cert`: The certificate binary.
  """
  @spec certinfo(binary) :: CFSSL.result()
  def certinfo(cert) do
    cert_file = Plug.Upload.random_file!("cert")
    File.write!(cert_file, cert)
    CFSSL.certinfo(cert_file)
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

  defp config_dir do
    :code.priv_dir(:nerves_hub_ca)
    |> to_string()
    |> Path.join("cfssl")
  end
end
