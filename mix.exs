defmodule AdsbRadar.MixProject do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"

  def project do
    [
      app: :adsb_radar,
      version: "0.1.0",
      elixir: "~> 1.7",
      target: @target,
      archives: [nerves_bootstrap: "~> 1.0"],
      deps_path: "deps/#{@target}",
      build_path: "_build/#{@target}",
      lockfile: "mix.lock.#{@target}",
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      aliases: [loadconfig: [&bootstrap/1]],
      deps: deps()
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {AdsbRadar.Application, []},
      extra_applications: [:logger, :runtime_tools, :dump_1090_client]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nerves, "~> 1.4", runtime: false},
      {:shoehorn, "~> 0.4"},
      {:ring_logger, "~> 0.6"},
      {:scenic, "~> 0.10"},
      {:scenic_sensor, "~> 0.7"},
      {:phoenix_pubsub, ">= 1.1.0"},
      {:geocalc, "~> 0.5"},
      {:dump_1090_client, git: "https://github.com/fatty-arbuckle/dump-1090-client.git"}
    ] ++ deps(@target)
  end

  # Specify target specific dependencies
  defp deps("host") do
    [
      {:scenic_driver_glfw, "~> 0.10"}
    ]
  end

  defp deps(target) do
    [
      {:nerves_runtime, "~> 0.9"},
      {:scenic_driver_nerves_rpi, "~> 0.10"},
      {:scenic_driver_nerves_touch, "~> 0.10"}
    ] ++ system(target)
  end

  defp system("rpi"), do: [{:nerves_system_rpi, "~> 1.7", runtime: false}]
  defp system("rpi0"), do: [{:nerves_system_rpi0, "~> 1.7", runtime: false}]
  defp system("rpi2"), do: [{:nerves_system_rpi2, "~> 1.7", runtime: false}]
  defp system("rpi3"), do: [{:nerves_system_rpi3, "~> 1.7", runtime: false}]
  defp system("bbb"), do: [{:nerves_system_bbb, "~> 2.2", runtime: false}]
  defp system("ev3"), do: [{:nerves_system_ev3, "~> 1.4", runtime: false}]
  defp system("x86_64"), do: [{:nerves_system_x86_64, "~> 1.7", runtime: false}]
  defp system(target), do: Mix.raise("Unknown MIX_TARGET: #{target}")
end
