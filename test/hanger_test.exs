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

end
