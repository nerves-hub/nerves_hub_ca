defmodule NervesHubCA.APITest do
  use ExUnit.Case
  doctest NervesHubCA

  describe "create from CSR" do
    test "devices" do
      subject = "/O=My Org/CN=device-1234"
      key = X509.PrivateKey.new_ec(:secp256r1)
      csr = X509.CSR.new(key, subject)

      assert {:ok, %{cert: cert, issuer: issuer}} = NervesHubCA.sign_device_csr(csr)

      ca_certs = Path.join(NervesHubCA.Storage.working_dir(), "ca.pem")

      file = write_tmp("device.pem", cert)

      cert = X509.Certificate.from_pem!(cert)

      serial =
        cert
        |> X509.Certificate.serial()
        |> to_string()

      assert {_, 0} = openssl(["verify", "-CAfile", ca_certs, file])
      assert %{serial: ^serial} = NervesHubCA.Repo.get_by(NervesHubCA.Certificate, serial: serial)
      assert subject == X509.Certificate.subject(cert) |> X509.RDNSequence.to_string()
    end

    test "users" do
      subject = "/O=NervesHub/CN=user-1234"
      key = X509.PrivateKey.new_ec(:secp256r1)
      csr = X509.CSR.new(key, subject)

      ca_certs = Path.join(NervesHubCA.Storage.working_dir(), "ca.pem")

      assert {:ok, %{cert: cert, issuer: issuer}} = NervesHubCA.sign_user_csr(csr)

      file = write_tmp("user.pem", cert)

      cert = X509.Certificate.from_pem!(cert)

      serial =
        cert
        |> X509.Certificate.serial()
        |> to_string()

      assert {_, 0} = openssl(["verify", "-CAfile", ca_certs, file])
      assert %{serial: ^serial} = NervesHubCA.Repo.get_by(NervesHubCA.Certificate, serial: serial)
      assert subject == X509.Certificate.subject(cert) |> X509.RDNSequence.to_string()
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
