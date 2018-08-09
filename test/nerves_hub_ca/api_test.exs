defmodule NervesHubCA.APITest do
  use ExUnit.Case
  doctest NervesHubCA

  alias NervesHubCA.CFSSL
  alias NervesHubCA.Intermediate.CA.Server, as: CA

  describe "create certificate pairs" do
    test "devices" do
      serial = "device-1234"

      {:ok, %{"certificate" => cert}} = NervesHubCA.create_device_certificate(serial)

      {:ok, result} = CFSSL.certinfo(CA, %{certificate: cert})

      assert serial == get_in(result, ["subject", "organization"])
    end

    test "users" do
      username = "test@test.com"

      {:ok, %{"certificate" => cert}} = NervesHubCA.create_user_certificate(username)

      {:ok, result} = CFSSL.certinfo(CA, %{certificate: cert})

      assert username == get_in(result, ["subject", "organization"])
    end

    test "servers" do
      hostname = "api.nerves-hub.org"

      {:ok, %{"certificate" => cert}} = NervesHubCA.create_server_certificate(hostname)

      {:ok, result} = CFSSL.certinfo(CA, %{certificate: cert})

      assert hostname == get_in(result, ["subject", "common_name"])
    end
  end

  describe "create from CSR" do
    test "devices" do
      serial = "device-1234"

      csr =
        Path.expand("test/fixtures/device.csr")
        |> File.read!()

      {:ok, %{"cert" => cert}} = NervesHubCA.sign_device_csr(csr)

      {:ok, result} = CFSSL.certinfo(CA, %{certificate: cert})

      assert serial == get_in(result, ["subject", "organization"])
    end

    test "users" do
      username = "test@test.com"

      csr =
        Path.expand("test/fixtures/user.csr")
        |> File.read!()

      {:ok, %{"cert" => cert}} = NervesHubCA.sign_user_csr(csr)

      {:ok, result} = CFSSL.certinfo(CA, %{certificate: cert})

      assert username == get_in(result, ["subject", "organization"])
    end
  end
end
