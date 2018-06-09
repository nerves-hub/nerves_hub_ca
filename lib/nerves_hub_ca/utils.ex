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
end
