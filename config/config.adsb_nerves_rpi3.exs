use Mix.Config

config :dump_1090_client,
  address: "localhost",
  port: 30003

config :adsb_radar, :viewport, %{
  name: :main_viewport,
  default_scene: {AdsbRadar.Scene.Radar, nil},
  # size: {1920, 1080},
  size: {1600, 900},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Nerves.Rpi
    },
    # %{
    #   module: Scenic.Driver.Nerves.Touch,
    #   opts: [
    #     device: "FT5406 memory based driver",
    #     calibration: {{1, 0, 0}, {1, 0, 0}}
    #   ]
    # }
  ]
}
