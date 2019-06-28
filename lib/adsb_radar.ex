defmodule AdsbRadar.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @target Mix.Project.config()[:target]

  use Application

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    Dump1090Client.start_listener
    opts = [strategy: :one_for_one, name: SnTest.Supervisor]
    result = Supervisor.start_link([
        {Aircraft.Dump1090Runner, []},
        {Aircraft.Hanger, []}
      ] ++ children(@target), opts)
    result
  end

  # List all child processes to be supervised
  def children("host") do
    main_viewport_config = Application.get_env(:adsb_radar, :viewport)

    [
      {Scenic, viewports: [main_viewport_config]}
    ]
  end

  def children(_target) do
    main_viewport_config = Application.get_env(:adsb_radar, :viewport)

    [
      {Scenic, viewports: [main_viewport_config]}
    ]
  end
end
