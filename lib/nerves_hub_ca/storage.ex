defmodule NervesHubCA.Storage do
  def working_dir do
    Application.get_env(:nerves_hub_ca, :working_dir)
  end
end
