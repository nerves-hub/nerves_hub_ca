defmodule NervesHubCA.Utils do
  @timeout 5_000

  def http_request(method, url, body \\ "", http_opts \\ []) do
    headers = [
      {'User-Agent', 'NervesHubCA'},
      {'Content-Type', 'application/json'}
    ]

    url = String.to_charlist(url)

    http_opts =
      http_opts
      |> Keyword.put_new(:timeout, @timeout)

    req =
      case method do
        :get -> {url, headers}
        _ -> {url, headers, 'application/json', body}
      end

    resp = :httpc.request(method, req, http_opts, [], :nerves_hub_ca)

    case resp do
      {:ok, {{_, status_code, _}, _headers, body}} ->
        {:ok, status_code, to_string(body)}

      error ->
        error
    end
  end

  def cert_files_to_der(cert_files) when is_list(cert_files) do
    Enum.reduce(cert_files, [], fn cert_file, acc ->
      case File.read(cert_file) do
        {:ok, cert} ->
          [{:Certificate, cert, _}] = :public_key.pem_decode(cert)
          [cert | acc]

        _ ->
          acc
      end
    end)
  end
end
