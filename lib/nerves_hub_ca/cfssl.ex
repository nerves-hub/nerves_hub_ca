defmodule NervesHubCA.CFSSL do
  use GenServer

  import NervesHubCA.Utils

  @endpoint "api/v1/cfssl"

  @init_poll 200
  @start_limit 10

  @type result :: {:ok, binary} | {:error, reason :: any}

  def child_spec(opts, genserver_opts) do
    port = opts[:port]
    id = Module.concat(__MODULE__, to_string(port))

    %{
      id: id,
      start: {__MODULE__, :start_link, [opts, genserver_opts]}
    }
  end

  @doc """
  Start a CFSSL Server

  parameters:
    `address`: The interface address to run cfssl on.
    `port`: the port number the cfssl server should run on. 
    `ca`: The path to the ca certificate file.
    `ca_key`: The path to the ca certificate private key file.
  """
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts, genserver_opts \\ []) do
    GenServer.start_link(__MODULE__, opts, genserver_opts)
  end

  @doc """
  Return the path to the ca cert the cfssl instance is configured to use
  """
  @spec ca_cert(pid) :: file_path :: binary | nil
  def ca_cert(pid) do
    GenServer.call(pid, :ca_cert)
  end

  @doc """
  Get the status of the cfssl instance
  """
  @spec status(pid) :: :starting | :ready
  def status(pid) do
    GenServer.call(pid, :status)
  end

  @doc """
  https://github.com/cloudflare/cfssl/blob/master/doc/api/endpoint_init_ca.txt
  """
  @spec init_ca(pid, Map.t() | binary) :: result
  def init_ca(pid, params) do
    request(pid, :post, "init_ca", params)
    |> decode_resp
  end

  @doc """
  https://github.com/cloudflare/cfssl/blob/master/doc/api/endpoint_certinfo.txt
  """
  @spec certinfo(pid, Map.t() | binary) :: result
  def certinfo(pid, params) do
    request(pid, :post, "certinfo", params)
    |> decode_resp
  end

  @doc """
  https://github.com/cloudflare/cfssl/blob/master/doc/api/endpoint_newcert.txt
  """
  @spec newcert(pid, Map.t() | binary) :: result
  def newcert(pid, params) do
    request(pid, :post, "newcert", params)
    |> decode_resp
  end

  def request(_, _, _, _ \\ "")

  def request(pid, method, endpoint, params) when is_binary(params) do
    GenServer.call(pid, {:request, method, endpoint, params})
  end

  def request(pid, method, endpoint, params) do
    case Jason.encode(params) do
      {:ok, params} -> request(pid, method, endpoint, params)
      error -> error
    end
  end

  def wait(pid) do
    fun = fn fun ->
      receive do
        :ready ->
          :ok

        _ ->
          send(self(), status(pid))
          fun.(fun)
      after
        0 ->
          send(self(), status(pid))
          fun.(fun)
      end
    end

    fun.(fun)
  end

  def init(opts) do
    opts = default_opts(opts)

    address = opts[:address]
    port = opts[:port]

    ca = Keyword.get(opts, :ca, "")
    ca_key = Keyword.get(opts, :ca_key, "")
    ca_config = Keyword.get(opts, :ca_config, "")
    ca_csr = Keyword.get(opts, :ca_csr)

    {:ok, pid} =
      MuonTrap.Daemon.start_link(
        "cfssl",
        [
          "serve",
          "-ca",
          ca,
          "-ca-key",
          ca_key,
          "-address",
          address,
          "-port",
          to_string(port),
          "-config",
          ca_config
        ],
        []
      )

    send(self(), :init)

    {:ok,
     %{
       address: address,
       port: port,
       server: pid,
       ca: ca,
       csr: ca_csr,
       start_attempts: 0,
       status: :starting
     }}
  end

  def handle_call(:ca_cert, _from, s) do
    {:reply, s.ca, s}
  end

  def handle_call(:status, _from, s) do
    {:reply, s.status, s}
  end

  def handle_call({:request, method, endpoint, params}, _from, s) do
    url = url(endpoint, s)
    resp = http_request(method, url, params)

    {:reply, resp, s}
  end

  def handle_info(:init, %{start_attempts: attempt} = s) when attempt <= @start_limit do
    url = url("init_ca", s)
    body = Jason.encode!(%{"hosts" => ["localhost"], "names" => [%{"O" => "NervesHub"}]})

    s =
      case http_request(:post, url, body) do
        {:ok, 200, _} ->
          %{s | status: :ready}

        _resp ->
          Process.send_after(self(), :init, @init_poll)
          %{s | start_attempts: s.start_attempts + 1}
      end

    {:noreply, s}
  end

  def handle_info(:init, s) do
    {:stop, :failed_to_start_cfssl, s}
  end

  defp default_opts(opts) do
    Application.get_env(:nerves_hub_ca, :cfssl_defaults, [])
    |> Keyword.merge(opts)
  end

  defp url(endpoint, s) do
    "http://#{s.address}:#{s.port}/#{@endpoint}/#{endpoint}"
  end

  defp decode_resp(resp) do
    case resp do
      {:ok, status, body} when status >= 200 and status < 300 ->
        case Jason.decode(body) do
          {:ok, %{"success" => true, "result" => result}} ->
            {:ok, result}

          error ->
            error
        end

      error ->
        error
    end
  end
end
