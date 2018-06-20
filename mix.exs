defmodule NervesHubCA.MixProject do
  use Mix.Project

  def project do
    [
      app: :nerves_hub_ca,
      version: "0.1.0",
      elixir: "~> 1.6",
      source_url: "https://github.com/nerves-hub/nerves_hub_ca",
      start_permanent: Mix.env() == :prod,
      docs: [extras: ["README.md"], main: "readme"],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets],
      mod: {NervesHubCA.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.5"},
      {:cowboy, "~> 2.1"},
      {:jason, "~> 1.0"},
      {:muontrap, "~> 0.3"},
      {:distillery, "~> 1.5"},
      {:ex_doc, "~> 0.18", only: [:test, :dev]}
    ]
  end
end
