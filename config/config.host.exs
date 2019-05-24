use Mix.Config

config :adsb_radar, :viewport, %{
  name: :main_viewport,
  default_scene: {AdsbRadar.Scene.Radar, nil},
  size: {1024, 780},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      opts: [title: "MIX_TARGET=host, app = :adbs_radar"]
    }
  ]
}
