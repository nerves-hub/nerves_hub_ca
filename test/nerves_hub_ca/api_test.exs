defmodule NervesHubCA.APITest do
  use ExUnit.Case
  doctest NervesHubCA

  alias NervesHubCA.CFSSL
  alias NervesHubCA.Intermediate.CA.Server, as: CA

  test "create device certificate" do
    serial = "123456"

    {:ok, %{"certificate" => cert}} = NervesHubCA.create_device_certificate(serial)

    {:ok, result} = CFSSL.certinfo(CA, %{certificate: cert})

    assert serial == get_in(result, ["subject", "organization"])
  end

  test "create user certificate" do
    username = "test@test.com"

    {:ok, %{"certificate" => cert}} = NervesHubCA.create_user_certificate(username)

    {:ok, result} = CFSSL.certinfo(CA, %{certificate: cert})

    assert username == get_in(result, ["subject", "organization"])
  end

  test "create server certificate" do
    hostname = "api.nerves-hub.org"

    {:ok, %{"certificate" => cert}} = NervesHubCA.create_server_certificate(hostname)

    {:ok, result} = CFSSL.certinfo(CA, %{certificate: cert})

    assert hostname == get_in(result, ["subject", "common_name"])
  end
end
