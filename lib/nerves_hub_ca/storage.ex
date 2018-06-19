defmodule NervesHubCA.Storage do
  @working_dir "/tmp"

  def working_dir do
    Application.get_env(:nerves_hub_ca, :working_dir, @working_dir)
  end
end
