defmodule Shotty.Fetcher do
  use GenServer
  require Logger
  alias Shotty.Indexer

  def start_link(opts) do
    {paths, opts} = Keyword.pop!(opts, :paths)
    opts = Keyword.put_new(opts, :name, __MODULE__)

    paths =
      Map.new(paths, fn {path, config} ->
        {Atom.to_string(path), Indexer.configure(config)}
      end)

    GenServer.start_link(__MODULE__, paths, opts)
  end

  def fetch(path, index_or_range, pid \\ __MODULE__)

  def fetch(path, index, pid) when is_integer(index) do
    with {:ok, files} <- GenServer.call(pid, {:latest, path, index}),
         true <- Enum.count(files) >= index do
      {:ok, List.first(files)}
    else
      false -> {:error, :index_not_found}
    end
  end

  def fetch(path, min..max, pid) when min >= 1 do
    with {:ok, all_files} <- GenServer.call(pid, {:latest, path, max}),
         [_ | _] = files <- Enum.drop(all_files, -(min - 1)) do
      {:ok, files}
    else
      [] -> {:error, :index_not_found}
    end
  end

  @impl true
  def init(paths) when is_map(paths) do
    Logger.info(
      "Starting #{inspect(__MODULE__)} with #{Enum.count(paths)} paths: #{Map.keys(paths) |> Enum.sort() |> Enum.join(", ")}"
    )

    {:ok, paths}
  end

  @impl true
  def handle_call({:latest, path, count}, _from, paths) do
    rval =
      case Map.fetch(paths, path) do
        {:ok, indexer} -> {:ok, Indexer.latest(indexer, count)}
        :error -> {:error, :path_not_found}
      end

    {:reply, rval, paths}
  end
end
