defmodule Aircraft.Hanger do
  use GenServer

  @purge_interval 600

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
        aircraft: %{},
        center: [0.0, 0.0],
        extents: [[90.0, -90.0], [90.0, -90.0]]
      }
    }
  end

  def handle_call(:info, _from, state) do
    {:reply, state, state}
  end


  def handle_info(
    {:update, incoming},
    %{aircraft: aircraft, center: center, extents: [[min_lat, max_lat], [min_long, max_long]] } = state
  ) do
    updated_aircraft = update_aircraft(aircraft, incoming)
    {updated_center, updated_extents} = update_extents(
      incoming,
      center,
      [[min_lat, max_lat], [min_long, max_long]]
    )


    now = DateTime.to_unix(DateTime.utc_now)
    updated_aircraft = Enum.reduce(
      updated_aircraft, %{},
      fn {key, bird}, acc ->
        acc |> put_bird({key, bird}, updated_center, now)
      end
    )

    # TODO
    # removal_threshold = DateTime.to_unix(DateTime.utc_now) - 5*60
    #   Enum.filter(updated_aircraft, fn bird ->
    #     bird.last_seen > removal_threshold
    #   end)

    # current aircraft information to the state
    state = %{ state |
      aircraft: updated_aircraft,
      extents: updated_extents,
      center: updated_center
    }

    { :noreply, state }
  end

  def handle_info({:update, %{icoa: _icoa, latitude: nil, longitude: nil}}, state) do
    { :noreply, state }
  end

  defp put_bird(acc, {_, %{latitude: nil, longitude: _}}, _, _), do: acc
  defp put_bird(acc, {_, %{latitude: _, longitude: nil}}, _, _), do: acc
  defp put_bird(acc, {_, %{last_seen: last_seen}}, _, now) when (now - last_seen) > @purge_interval, do: acc
  defp put_bird(acc, {key, %{latitude: latitude, longitude: longitude} = bird}, updated_center, _) do
    if latitude != nil and longitude != nil do
      Map.put(
        acc,
        key,
        Map.merge(bird, %{
          bearing: Geocalc.bearing(updated_center, [bird.latitude, bird.longitude]),
          distance: Geocalc.distance_between(updated_center, [bird.latitude, bird.longitude])
        })
      )
    else
      acc
    end
  end

  defp update_aircraft(aircraft, incoming) do
    # find the aircraft
    current_bird = Map.get(aircraft, incoming.icoa, %{
      icoa: incoming.icoa,
      latitude: nil,
      longitude: nil,
      callsign: nil,
      heading: nil,
      speed: nil,
      altitude: nil,
      path: []
    })

    current_bird = if current_bird.latitude != nil and current_bird.longitude != nil do
      Map.put(current_bird, :path,
        [[current_bird.latitude, current_bird.longitude]] ++ current_bird.path)
    else
      current_bird
    end

    # update what isn't nil
    current_bird = update_bird(current_bird, incoming, :latitude)
    current_bird = update_bird(current_bird, incoming, :longitude)
    current_bird = update_bird(current_bird, incoming, :callsign)
    current_bird = update_bird(current_bird, incoming, :heading)
    current_bird = update_bird(current_bird, incoming, :speed)
    current_bird = update_bird(current_bird, incoming, :altitude)
    current_bird = Map.put(current_bird, :last_seen, DateTime.to_unix(DateTime.utc_now))

    # put the current bird back in the hanger
    Map.put(aircraft, incoming.icoa, current_bird)
  end

  # current_bird, incoming, :latitude
  defp update_bird(current, incoming, key) do
    case Map.has_key?(incoming, key) do
      true ->
        {:ok, value} = Map.fetch(incoming, key)
        case value do
          nil ->
            current
          v   ->
            Map.put(current, key, v)
        end
      false ->
        current
    end
  end

  defp update_extents(incoming, center, [[min_lat, max_lat], [min_long, max_long]]) do
    if Map.has_key?(incoming, :latitude) and incoming.latitude != nil and
        Map.has_key?(incoming, :longitude) and incoming.longitude != nil do
      min_lat = if(incoming.latitude < min_lat, do: incoming.latitude, else: min_lat)
      max_lat = if(incoming.latitude > max_lat, do: incoming.latitude, else: max_lat)
      min_long = if(incoming.longitude < min_long, do: incoming.longitude, else: min_long)
      max_long = if(incoming.longitude > max_long, do: incoming.longitude, else: max_long)
      center = Geocalc.geographic_center([[min_lat, min_long], [max_lat, max_long]])
      {center, [[min_lat, max_lat], [min_long, max_long]]}
    else
      {center, [[min_lat, max_lat], [min_long, max_long]]}
    end
  end



end
