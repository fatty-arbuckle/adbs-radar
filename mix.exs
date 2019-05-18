defmodule AdsbRadar.MixProject do
  use Mix.Project

  def project do
    [
      app: :adsb_radar,
      version: "0.1.0",
      elixir: "~> 1.7",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {AdsbRadar, []},
      extra_applications: [:dump_1090_client]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic, "~> 0.10"},
      {:scenic_driver_glfw, "~> 0.10", targets: :host},
      {:phoenix_pubsub, ">= 1.1.0"},
      {:geocalc, "~> 0.5"},
      {:dump_1090_client, git: "https://github.com/fatty-arbuckle/dump-1090-client.git"}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end

end
