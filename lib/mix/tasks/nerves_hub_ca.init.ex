defmodule Mix.Tasks.NervesHubCa.Init do
  @path Path.join(File.cwd!(), "etc/cfssl")

  @switches [
    path: :string
  ]

  def run(args) do
    {opts, _args} = OptionParser.parse!(args, strict: @switches)

    path = opts[:path] || Application.get_env(:nerves_hub_ca, :working_dir) || @path

    File.mkdir_p(path)

    %{cert: root_ca} = gen_ca_cert("root-ca", path)
    %{cert: server_ca} = gen_int_ca_cert("intermediate-server-ca", path)
    %{cert: device_ca} = gen_int_ca_cert("intermediate-device-ca", path)
    %{cert: user_ca} = gen_int_ca_cert("intermediate-user-ca", path)

    # Create a pem of the ca trust chain
    ca_cert = Path.join(path, "ca.pem")

    [root_ca, server_ca, device_ca, user_ca]
    |> Enum.each(&File.write!(ca_cert, File.read!(&1), [:append]))

    gen_server_cert("ca.nerves-hub.org", path)
    gen_client_cert("ca-client", path)
  end

  defp gen_client_cert(name, path) do
    config = Path.join(config_dir(), "ca-config.json")
    ca_cert = Path.join(path, "intermediate-server-ca.pem")
    ca_key = Path.join(path, "intermediate-server-ca-key.pem")

    csr = %{
      "CN" => name,
      "key" => %{
        "algo" => "ecdsa",
        "size" => 256
      }
    }

    csr = Jason.encode!(csr)
    csr_path = Path.join(path, "#{name}.json")
    File.write(csr_path, csr)

    cfssl(
      "gencert -ca #{ca_cert} -ca-key #{ca_key} -config #{config} -profile client -hostname #{
        name
      } #{csr_path}",
      path
    )
    |> write_certs(name, path)
  end

  defp gen_server_cert(hostname, path) do
    config = Path.join(config_dir(), "ca-config.json")
    ca_cert = Path.join(path, "intermediate-server-ca.pem")
    ca_key = Path.join(path, "intermediate-server-ca-key.pem")

    csr = %{
      "CN" => hostname,
      "key" => %{
        "algo" => "ecdsa",
        "size" => 256
      }
    }

    csr = Jason.encode!(csr)
    csr_path = Path.join(path, "#{hostname}.json")
    File.write(csr_path, csr)

    cfssl(
      "gencert -ca #{ca_cert} -ca-key #{ca_key} -config #{config} -profile server -hostname #{
        hostname
      } #{csr_path}",
      path
    )
    |> write_certs(hostname, path)
  end

  defp gen_int_ca_cert(name, path) do
    gen_ca_cert(name, path)
    |> root_sign(path)
    |> write_certs(name, path)
  end

  defp gen_ca_cert(name, path) do
    csr =
      config_dir()
      |> Path.join("#{name}-csr.json")

    cfssl("gencert -initca #{csr}", path)
    |> write_certs(name, path)
  end

  defp root_sign(%{csr: csr}, path) do
    config = Path.join(config_dir(), "root-to-intermediate-config.json")
    ca_cert = Path.join(path, "root-ca.pem")
    ca_key = Path.join(path, "root-ca-key.pem")
    cfssl("sign -ca #{ca_cert} -ca-key #{ca_key} -config #{config} #{csr}", path)
  end

  defp config_dir do
    :code.priv_dir(:nerves_hub_ca)
    |> to_string()
    |> Path.join("cfssl")
  end

  defp cfssl(args, path) when is_binary(args) do
    String.split(args, " ")
    |> cfssl(path)
  end

  defp cfssl(args, path) when is_list(args) do
    IO.inspect(args)

    case System.cmd("cfssl", args, cd: path) do
      {ret, 0} ->
        Jason.decode!(ret)

      {error, _code} ->
        Mix.raise("cfssl returned an error: #{inspect(error)}")
    end
  end

  defp write_certs(certs, name, path) do
    cert_path = Path.join(path, "#{name}.pem")
    File.write!(cert_path, certs["cert"])

    csr_path = Path.join(path, "#{name}-csr.pem")
    File.write!(csr_path, certs["csr"])

    case Map.get(certs, "key") do
      nil ->
        %{cert: cert_path, csr: csr_path}

      key ->
        key_path = Path.join(path, "#{name}-key.pem")
        File.write!(key_path, key)
        %{cert: cert_path, csr: csr_path, key: key_path}
    end
  end
end
