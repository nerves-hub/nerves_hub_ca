defmodule NervesHubCA.APITest do
  use ExUnit.Case
  doctest NervesHubCA

  describe "create from CSR" do
    test "devices" do
      csr =
        Path.expand("test/fixtures/device-csr.pem")
        |> File.read!()
        |> X509.CSR.from_pem!()

      assert {:ok, %{cert: cert, issuer: issuer}} = NervesHubCA.sign_device_csr(csr)

      ca_certs = Path.join(NervesHubCA.Storage.working_dir(), "ca.pem")

      file = write_tmp("device.pem", cert)
      assert {_, 0} = openssl(["verify", "-CAfile", ca_certs, file])

      serial =
        cert
        |> X509.Certificate.from_pem!()
        |> X509.Certificate.serial()
        |> to_string()

      assert %{serial: ^serial} = NervesHubCA.Repo.get_by(NervesHubCA.Certificate, serial: serial)
    end

    test "users" do
      csr =
        Path.expand("test/fixtures/user-csr.pem")
        |> File.read!()
        |> X509.CSR.from_pem!()

      ca_certs = Path.join(NervesHubCA.Storage.working_dir(), "ca.pem")

      assert {:ok, %{cert: cert, issuer: issuer}} = NervesHubCA.sign_user_csr(csr)

      file = write_tmp("user.pem", cert)
      assert {_, 0} = openssl(["verify", "-CAfile", ca_certs, file])

      serial =
        cert
        |> X509.Certificate.from_pem!()
        |> X509.Certificate.serial()
        |> to_string()

      assert %{serial: ^serial} = NervesHubCA.Repo.get_by(NervesHubCA.Certificate, serial: serial)
    end
  end

  defp openssl(args) do
    openssl = System.get_env("OPENSSL_PATH") || "openssl"

    System.cmd(openssl, List.wrap(args), stderr_to_stdout: true)
  end

  defp write_tmp(name, data) do
    tmp_file = Path.expand("test/tmp/" <> name)

    File.write!(tmp_file, data)

    tmp_file
  end
end
