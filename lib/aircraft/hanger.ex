defmodule Aircraft.Hanger do
  use GenServer

  # Client

  def start_link(data) when is_list(data) do
    GenServer.start_link(__MODULE__, data, name: __MODULE__)
  end

  def info() do
    GenServer.call(__MODULE__, :info)
  end

  # Server (callbacks)

  def init(_data) do
    Phoenix.PubSub.PG2.start_link :aircraft_channel, []
    Phoenix.PubSub.subscribe :aircraft_channel, "aircraft:update"
    {
      :ok,
      %{
        aircraft: [],
        center: [0.0, 0.0],
        extents: [[90.0, -90.0], [90.0, -90.0]]
      }
    }
  end

  def handle_call(:info, _from, state) do
    {:reply, state, state}
  end



  def handle_info(
    {:update, %{icoa: icoa, latitude: latitude, longitude: longitude}},
    %{aircraft: aircraft, center: _center, extents: [[min_lat, max_lat], [min_long, max_long]] } = state
  ) when latitude != nil and longitude != nil do

    # filter out icoa if we already have it
    filtered_list = Enum.filter(aircraft, fn bird ->
      bird.icoa != icoa
    end)

    # extend extents
    min_lat = if(latitude < min_lat, do: latitude, else: min_lat)
    max_lat = if(latitude > max_lat, do: latitude, else: max_lat)
    min_long = if(longitude < min_long, do: longitude, else: min_long)
    max_long = if(longitude > max_long, do: longitude, else: max_long)

    # calculate the center
    center = Geocalc.geographic_center([[min_lat, min_long], [max_lat, max_long]])

    removal_threshold = DateTime.to_unix(DateTime.utc_now) - 5*60

    # update bearing and distance
    updated_aircraft = Enum.map(
      filtered_list ++ [%{
        icoa: icoa,
        latitude: latitude,
        longitude: longitude,
        last_seen: DateTime.to_unix(DateTime.utc_now)
      }], fn bird ->
        %{
          icoa: bird.icoa,
          latitude: bird.latitude,
          longitude: bird.longitude,
          bearing: Geocalc.bearing(center, [bird.latitude, bird.longitude]),
          # distance is in meters
          distance: Geocalc.distance_between(center, [bird.latitude, bird.longitude]),
          last_seen: bird.last_seen
        }
    end)

    Enum.filter(updated_aircraft, fn bird ->
      bird.last_seen > removal_threshold
    end)

    # current aircraft information to the state
    state = %{ state |
      aircraft: updated_aircraft,
      extents: [[min_lat, max_lat], [min_long, max_long]],
      center: center
    }

    { :noreply, state }
  end
  def handle_info({:update, %{icoa: _icoa, latitude: nil, longitude: nil}}, state) do
    { :noreply, state }
  end

end
