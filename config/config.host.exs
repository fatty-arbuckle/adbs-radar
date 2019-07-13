use Mix.Config

config :dump_1090_client,
  # address: "192.168.1.233",
  address: "localhost",
  port: 30003

config :adsb_radar, :viewport, %{
  name: :main_viewport,
  default_scene: {AdsbRadar.Scene.Radar, nil},
  size: {1600, 900},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      opts: [title: "MIX_TARGET=host, app = :adbs_radar"]
    }
  ]
}
