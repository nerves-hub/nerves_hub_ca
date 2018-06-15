defmodule NervesHubCA do
  alias NervesHubCA.CFSSL

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
      profile: "client"
    }

    CFSSL.newcert(RootCA, params)
  end
end
