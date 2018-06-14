defmodule NervesHubCA.APITest do
  use ExUnit.Case
  doctest NervesHubCA

  alias NervesHubCA.CFSSL

  test "create device certificate" do
    serial = "123456"

    {:ok, %{"certificate" => cert}} = NervesHubCA.create_device_certificate(serial)

    NervesHubCA.working_dir()
    |> Path.join("device.pem")
    |> File.write(cert)

    {:ok, result} = CFSSL.certinfo(RootCA, %{certificate: cert})

    assert serial == get_in(result, ["subject", "organization"])
  end
end
