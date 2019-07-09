defmodule HangerTest do
  use ExUnit.Case

  @icoa "AAABBC"
  @callsign "JBU123"
  @heading 42

  test "aircraft hanger records aircraft correctly" do
    {hanger_started, _} = Aircraft.Hanger.start_link([])
    assert hanger_started == :ok
    assert %{} == Aircraft.Hanger.info().aircraft

    Process.send(Aircraft.Hanger, {:update, %{icoa: @icoa, latitude: 5.0, longitude: 6.0}}, [:noconnect])
    assert 1 == Enum.count(Aircraft.Hanger.info().aircraft)
    bird = Map.get(Aircraft.Hanger.info().aircraft, @icoa)
    assert bird.icoa == @icoa
    assert bird.latitude == 5.0
    assert bird.longitude == 6.0
    assert bird.callsign == nil
    assert bird.heading == nil

    Process.send(Aircraft.Hanger, {:update, %{icoa: @icoa, latitude: 15.0, longitude: 16.0}}, [:noconnect])
    assert 1 == Enum.count(Aircraft.Hanger.info().aircraft)
    bird = Map.get(Aircraft.Hanger.info().aircraft, @icoa)
    assert bird.icoa == @icoa
    assert bird.latitude == 15.0
    assert bird.longitude == 16.0
    assert bird.callsign == nil
    assert bird.heading == nil

    Process.send(Aircraft.Hanger, {:update, %{icoa: @icoa, callsign: @callsign}}, [:noconnect])
    assert 1 == Enum.count(Aircraft.Hanger.info().aircraft)
    bird = Map.get(Aircraft.Hanger.info().aircraft, @icoa)
    assert bird.icoa == @icoa
    assert bird.latitude == 15.0
    assert bird.longitude == 16.0
    assert bird.callsign == @callsign
    assert bird.heading == nil

    Process.send(Aircraft.Hanger, {:update, %{icoa: @icoa, heading: @heading}}, [:noconnect])
    assert 1 == Enum.count(Aircraft.Hanger.info().aircraft)
    bird = Map.get(Aircraft.Hanger.info().aircraft, @icoa)
    assert bird.icoa == @icoa
    assert bird.latitude == 15.0
    assert bird.longitude == 16.0
    assert bird.callsign == @callsign
    assert bird.heading == @heading
  end

  test "bearings" do
    IO.inspect(Geocalc.bearing([10.0, 10.0], [15.0, 10.0]), label: "NORTH")
    IO.inspect(Geocalc.bearing([10.0, 10.0], [10.0, 15.0]), label: "EAST")
    IO.inspect(Geocalc.bearing([10.0, 10.0], [ 5.0, 10.0]), label: "SOUTH")
    IO.inspect(Geocalc.bearing([10.0, 10.0], [10.0,  5.0]), label: "WEST")
    IO.inspect(Aircraft.Hanger.get_bearing([10.0, 10.0], [15.0, 10.0]), label: "NORTH")
    IO.inspect(Aircraft.Hanger.get_bearing([10.0, 10.0], [10.0, 15.0]), label: "EAST")
    IO.inspect(Aircraft.Hanger.get_bearing([10.0, 10.0], [ 5.0, 10.0]), label: "SOUTH")
    IO.inspect(Aircraft.Hanger.get_bearing([10.0, 10.0], [10.0,  5.0]), label: "WEST")
    assert 0.0 == Geocalc.bearing([10.0, 10.0], [15.0, 10.0])
  end

end
