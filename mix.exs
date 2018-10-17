defmodule NervesHubCA.MixProject do
  use Mix.Project

  def project do
    [
      app: :nerves_hub_ca,
      version: "0.4.0",
      elixir: "~> 1.6",
      source_url: "https://github.com/nerves-hub/nerves_hub_ca",
      start_permanent: Mix.env() == :prod,
      docs: docs(),
      deps: deps(),
      aliases: [test: ["nerves_hub_ca.init", "test"]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets],
      mod: {NervesHubCA.Application, []}
    ]
  end

  defp docs do
    [
      extras: [
        "README.md",
        "docs/Generating Certificates with CFSSL.md"
      ],
      main: "readme"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:x509, path: "../x509"},
      {:plug, "~> 1.6"},
      {:cowboy, "~> 2.1"},
      {:jason, "~> 1.0"},
      {:distillery, "~> 1.5"},
      {:ex_doc, "~> 0.18.0", only: [:test, :dev], runtime: false}
    ]
  end
end
