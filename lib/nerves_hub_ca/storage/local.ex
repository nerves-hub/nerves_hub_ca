defmodule NervesHubCA.Storage.Local do
  alias NervesHubCA.Storage

  @behaviour NervesHubCA.Storage

  def fetch(filename) do
    file =
      Storage.working_dir()
      |> Path.join(filename)

    if File.exists?(file) do
      {:ok, file}
    else
      {:error, :file_not_found}
    end
  end

  def write(filename, data) do
    Storage.working_dir()
    |> Path.join(filename)
    |> File.write(data)
  end
end
