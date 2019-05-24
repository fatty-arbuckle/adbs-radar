defmodule AdsbRadar.Scene.Radar do
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [circle: 3, line: 3, sector: 3, text: 3]

  @target_color :gray

  @frame_ms 26

  # Constants
  @graph Graph.build(font: :roboto, font_size: 36)

  # Initialize the game scene
  def init(_arg, opts) do
    viewport = opts[:viewport]

    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    center = { trunc(vp_width / 2), trunc(vp_height / 2) }
    size = Enum.min(Tuple.to_list(center))

    # start a very simple animation timer
    {:ok, timer} = :timer.send_interval(@frame_ms, :frame)

    # The entire game state will be held here
    state = %{
      viewport: viewport,
      graph: @graph,
      frame_count: 1,
      frame_timer: timer,
      center: center,
      size: size,
      # Game objects
      objects: %{
        sweep: %{
          center: center,
          size: size,
          arc_location: 0,
          arc_length: 45.0,
          speed: 1
        },
        indicator: %{
          center: center,
        },
        aircraft: %{
          center: center,
          size: size,
        }
      }
    }

    # Update the graph and push it to be rendered
    graph = state.graph
    |> draw_target(state.center, state.size)
    |> draw_game_objects(0, state.objects)

    %{ state | graph: graph }

    {:ok, state, push: graph}
  end

  defp draw_target(graph, {cx, cy}, size) do
    stroke_width = 2
    tick_length = 8
    length = size - stroke_width

    graph
    |> circle(length, stroke: {stroke_width, :gray}, translate: {cx, cy})
    |> circle(trunc(length * 0.75), stroke: {stroke_width, @target_color}, translate: {cx, cy})
    |> circle(trunc(length * 0.50), stroke: {stroke_width, @target_color}, translate: {cx, cy})
    |> circle(trunc(length * 0.25), stroke: {stroke_width, @target_color}, translate: {cx, cy})
    |> draw_target_lines(cx, cy, length, stroke_width, tick_length)
  end

  defp draw_target_lines(graph, cx, cy, length, stroke_width, tick_length) do
    graph
    |> draw_target_line(cx, cy, length, 0, stroke_width)
    |> draw_target_line(cx, cy, 0, length, stroke_width)
    |> draw_target_line_ticks({cx,cy}, length, tick_length)
  end

  defp draw_target_line(graph, cx, cy, x_offset, y_offset, stroke_width) do
    graph
    |> line({{cx-x_offset,cy-y_offset}, {cx+x_offset, cy+y_offset}}, stroke: {stroke_width, @target_color})
  end

  defp draw_target_line_ticks(graph, {sx, sy}, length, tick_length) do
    Enum.reduce(
      :lists.seq(-100, 100, 5),
      graph, fn p, graph ->
        offset = trunc(length * (p/100))
        x = sx + offset
        y = sy + offset
        graph
        |> line({{x, sy - tick_length}, {x, sy + tick_length}}, stroke: {1, @target_color})
        |> line({{sx - tick_length, y}, {sx + tick_length, y}}, stroke: {1, @target_color})
    end)
  end


  # Iterates over the object map, rendering each object
  defp draw_game_objects(graph, frame, object_map) do
    Enum.reduce(object_map, graph, fn {object_type, object_data}, graph ->
      draw_object(graph, object_type, frame, object_data)
    end)
  end


  defp draw_object(graph, :sweep, _frame, %{center: center, size: size, arc_location: arc_location, arc_length: arc_length}) do
    parts = 12
    Enum.reduce(
      :lists.seq(0, parts - 1),
      graph,
      fn i, graph ->
        graph |> draw_sector(
          center,
          size,
          arc_location - ((arc_length / parts) * i),
          arc_location - ((arc_length / parts) * (i+1)),
          130 - (10* i)
        )
      end
    )
    |> line({center, {size*:math.cos(degreesToRadians(arc_location)) + elem(center, 0), size*:math.sin(degreesToRadians(arc_location)) + elem(center, 1)}}, stroke: {3, :lime})
  end

  defp draw_object(graph, :indicator, _frame, %{center: {cx, cy}}) do
    color = case Dump1090Client.status do
      %{address: _address, connected: true} -> %{stroke: :lime, fill: :green}
      _                                     -> %{stroke: :gray, fill: :red}
    end
    tx = 2 * cx - 25
    ty = 2 * cy - 25
    graph
    |> circle(10, stroke: {2, color.stroke}, fill: color.fill, translate: {tx, ty})
    |> circle( 7, stroke: {1, color.stroke}, fill: color.fill, translate: {tx, ty})
    |> circle( 4, stroke: {1, color.stroke}, fill: color.fill, translate: {tx, ty})
    |> circle( 1, stroke: {1, color.stroke}, fill: color.fill, translate: {tx, ty})
  end

  defp draw_object(graph, :aircraft, _frame, %{center: {cx, cy}, size: size}) do

    idle_threshold = DateTime.to_unix(DateTime.utc_now) - 15
    hanger_data =
      Map.values(Aircraft.Hanger.info().aircraft)
      |> Enum.filter(fn bird ->
        bird.latitude != nil and bird.longitude != nil
      end)
    if Enum.count(hanger_data) > 0 do
      furtherest_bird = Enum.max_by(hanger_data, fn bird -> bird.distance end)
      maxRange = fit_distance(furtherest_bird.distance)

      # TODO pass in size to get this number
      scale = maxRange / 390.0

      # IO.inspect(furtherest_bird.distance, label: "furtherest_bird")
      # IO.inspect(maxRange, label: "maxRange")
      # IO.inspect(scale, label: "scale")
      # IO.inspect({cx, cy}, label: "center")


      graph = graph
      |> text(Float.to_string(maxRange/1_000) <> " km", font: :roboto, font_size: 12, translate: {cx + 8 + size, cy} )

      Enum.reduce(hanger_data, graph, fn bird, graph ->
        stroke = if(bird.last_seen < idle_threshold, do: {1, :gray}, else: {3, :lime})
        # IO.inspect(bird, label: "BIRD")
        x = (bird.distance/scale) * :math.cos(bird.bearing) + cx
        y = (bird.distance/scale) * :math.sin(bird.bearing) + cy

        label = if(bird.callsign != nil, do: bird.callsign, else: bird.icoa)
        graph
        |> circle( 5, stroke: stroke, translate: {x, y} )
        |> text( label, font: :roboto, font_size: 16, translate: {x + 8, y - 3} )
          # 5, fill: {:lime, alpha_from_frame(150, frame, aircraft.found_frame)}, translate: {x, y} )
        |> draw_heading(bird.heading, bird.speed, x, y, stroke)
      end)
    else
      graph
    end
  end

  defp draw_heading(graph, heading, _speed, _x, _y, _stroke) when heading == nil, do: graph
  defp draw_heading(graph, heading, speed, x, y, stroke) do
    speed = if speed == nil, do: 5, else: speed
    radians = Geocalc.degrees_to_radians(heading)
    heading_length = -5
    heading_xs = heading_length * :math.cos(radians) + x
    heading_ys = heading_length * :math.sin(radians) + y
    heading_length = (-40 * (speed / 1000)) - 5
    heading_xe = heading_length * :math.cos(radians) + x
    heading_ye = heading_length * :math.sin(radians) + y
    graph
    |> line({{heading_xs, heading_ys}, {heading_xe, heading_ye}}, stroke: stroke )
  end

  defp draw_sector(graph, center, size, start, finish, alpha) do
    graph
    |> sector(
      {size, degreesToRadians(start), degreesToRadians(finish)},
      [
        fill: {:lime, alpha},
        translate: center
      ]
    )
  end

  defp degreesToRadians(d) do
    (d * 2 * :math.pi) / 360
  end


  def handle_info(:frame, %{frame_count: frame_count} = state) do

    state = move_sweeper(state)

    graph = state.graph
    |> draw_target(state.center, state.size)
    |> draw_game_objects(state.frame_count, state.objects)
    # |> push_graph()

    %{ state | graph: graph }


    {:noreply, %{state | frame_count: frame_count + 1}, push: graph}
  end

  defp move_sweeper(%{objects: %{sweep: sweep}} = state) do
    put_in(state, [:objects, :sweep, :arc_location], rem((sweep.arc_location + sweep.speed), 360))
  end

  # defp fit_distance(f) when f <  10_000.0, do:  10_000.0
  defp fit_distance(f) when f <  25_000.0, do:  25_000.0
  # defp fit_distance(f) when f <  30_000.0, do:  30_000.0
  # defp fit_distance(f) when f <  40_000.0, do:  40_000.0
  defp fit_distance(f) when f <  50_000.0, do:  50_000.0
  # defp fit_distance(f) when f <  60_000.0, do:  60_000.0
  defp fit_distance(f) when f <  75_000.0, do:  75_000.0
  # defp fit_distance(f) when f <  80_000.0, do:  80_000.0
  # defp fit_distance(f) when f <  90_000.0, do:  90_000.0
  defp fit_distance(f) when f < 100_000.0, do: 100_000.0
  defp fit_distance(f) when f < 200_000.0, do: 200_000.0
  defp fit_distance(f) when f < 300_000.0, do: 300_000.0
  defp fit_distance(f) when f < 400_000.0, do: 400_000.0
  defp fit_distance(f) when f < 500_000.0, do: 500_000.0
  defp fit_distance(f), do: f
end
