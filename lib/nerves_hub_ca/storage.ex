defmodule NervesHubCA.Storage do
  alias __MODULE__

  @callback fetch(filename :: String.t()) ::
              {:ok, file_path :: binary}
              | {:error, reason :: any}

  @callback write(filename :: String.t(), data :: binary) ::
              :ok
              | {:error, reason :: any}

  def adapter do
    Application.get_env(:nerves_hub_ca, :storage_adapter, Storage.Local)
  end

  def working_dir do
    Application.get_env(:nerves_hub_ca, :working_dir, "/tmp")
  end

  def try_fetch(adapter, filename) do
    case adapter.fetch(filename) do
      {:ok, path} -> path
      _ -> ""
    end
  end
end
