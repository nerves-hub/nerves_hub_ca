defmodule NervesHubCA.Storage.S3 do
  @behaviour NervesHubCA.Storage

  alias NervesHubCA.Storage
  alias ExAws.S3

  def fetch(filename) do
    bucket = Keyword.get(config(), :bucket)

    S3.get_object(bucket, filename)
    |> ExAws.request()
    |> case do
      %{status_code: 200, body: file} ->
        :ok = Storage.Local.write(filename, file)
        Storage.Local.fetch(filename)

      error ->
        error
    end
  end

  def write(filename, data) do
    bucket = Keyword.get(config(), :bucket)

    S3.put_object(bucket, filename, data)
    |> ExAws.request()
    |> case do
      {:ok, %{status_code: 200}} ->
        :ok

      error ->
        error
    end
  end

  defp config() do
    Application.get_env(:nerves_hub_ca, __MODULE__)
  end
end
