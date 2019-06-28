defmodule Aircraft.Dump1090Runner do
  use GenServer
  require Logger

  # Client

  def start_link(data) do
    GenServer.start_link(__MODULE__, data, name: __MODULE__)
  end

  # Server (callbacks)

  def init(_data) do
    schedule_work(0)
    {:ok, %{}}
  end

  def handle_info(:work, state) do
    do_work(state)
  end

  def handle_cast(:work, state) do
    do_work(state)
  end

  defp do_work(state) do
    try do
      System.cmd("dump1090", ["--net"])
      schedule_work(10)
      {:noreply, state}
    rescue
      error ->
        Logger.error("error running \"dump1090 --net\": #{error.original}")
        schedule_work(10)
        {:noreply, :error}
    end
  end

  defp schedule_work(delay) do
    Process.send_after(self(), :work, delay * 1000)
  end

end
