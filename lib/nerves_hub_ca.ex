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
end
