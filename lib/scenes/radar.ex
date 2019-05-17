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
    hanger_data = Aircraft.Hanger.info
    if Enum.count(hanger_data.aircraft) > 0 do
      furtherest_bird = Enum.max_by(hanger_data.aircraft, fn bird -> bird.distance end)
      scale = furtherest_bird.distance / 240

      graph = graph
      |> text(Float.to_string(Float.round(scale*size/1000, 1)) <> " km", font: :roboto, font_size: 12, translate: {cx + 8 + size, cy} )

      Enum.reduce(hanger_data.aircraft, graph, fn bird, graph ->
        stroke = if(bird.last_seen < idle_threshold, do: {1, :gray}, else: {3, :lime})
        x = (bird.distance/scale) * :math.cos(bird.bearing) + cx
        y = (bird.distance/scale) * :math.sin(bird.bearing) + cy
        graph
        |> circle( 5, stroke: stroke, translate: {x, y} )
        |> text( bird.icoa, font: :roboto, font_size: 16, translate: {x + 8, y - 3} )
          # 5, fill: {:lime, alpha_from_frame(150, frame, aircraft.found_frame)}, translate: {x, y} )
      end)
    else
      graph
    end
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

end
