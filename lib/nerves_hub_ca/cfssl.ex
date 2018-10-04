defmodule NervesHubCA.CFSSL do
  @type result :: {:ok, binary} | {:error, reason :: any}

  @doc """
  Get certificate information
   parameters:
    `cert`: The path to the certificate file.
  """
  @spec certinfo(cert_path :: binary) :: result()
  def certinfo(cert_path) do
    args = "-cert=#{cert_path}"
    cfssl("certinfo #{args}", File.cwd!())
  end

  @doc """
  Signs a client cert with a host name by a given CA and CA key
   parameters:
    `csr`: The path to the certificate signing request.
    `ca_cert`: The path to the ca certificate file.
    `ca_key`: The path to the ca certificate private key file.
    `config`: The path to the ca configuration file.
    `profile`: The ca configuration profile to use.
    `path`: The path to execute the command in.
  """
  @spec sign(binary, binary, binary, binary, binary, binary) :: result()
  def sign(csr, ca_cert, ca_key, config, profile, path \\ nil) do
    path = path || File.cwd!()
    args = "-ca #{ca_cert} -ca-key #{ca_key} -config #{config} -profile #{profile}"
    cfssl("sign #{args} #{csr}", path)
  end

  defp cfssl(args, path) when is_binary(args) do
    String.split(args, " ")
    |> cfssl(path)
  end

  defp cfssl(args, path) when is_list(args) do
    case System.cmd("cfssl", args, cd: path) do
      {ret, 0} ->
        Jason.decode(ret)

      error ->
        error
    end
  end
end
