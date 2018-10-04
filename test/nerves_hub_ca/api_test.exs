defmodule NervesHubCA.APITest do
  use ExUnit.Case
  doctest NervesHubCA

  describe "create from CSR" do
    test "devices" do
      serial = "device-1234"

      csr =
        Path.expand("test/fixtures/device.csr")
        |> File.read!()

      {:ok, %{"cert" => cert}} = NervesHubCA.sign_device_csr(csr)

      {:ok, result} = NervesHubCA.certinfo(cert)

      assert serial == get_in(result, ["subject", "organization"])
    end

    test "users" do
      username = "test@test.com"

      csr =
        Path.expand("test/fixtures/user.csr")
        |> File.read!()

      {:ok, %{"cert" => cert}} = NervesHubCA.sign_user_csr(csr)

      {:ok, result} = NervesHubCA.certinfo(cert)

      assert username == get_in(result, ["subject", "organization"])
    end
  end
end
