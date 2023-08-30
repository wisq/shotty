defmodule Shotty.Test.MockFetcher do
  use GenServer

  def start_link(handler) do
    GenServer.start_link(__MODULE__, handler, name: Shotty.Fetcher)
  end

  @impl true
  def init(handler) do
    {:ok, handler}
  end

  @impl true
  def handle_call({:latest, path, count}, _from, handler) do
    rval = handler.(path, count)
    {:reply, rval, :done}
  end
end
