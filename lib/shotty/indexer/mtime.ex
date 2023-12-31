defmodule Shotty.Indexer.Mtime do
  @behaviour Shotty.Indexer

  import Shotty.Indexer.Common

  defmodule Config do
    @enforce_keys [:path]
    defstruct(
      path: nil,
      # Default: regex that matches anything
      include: ~r//,
      # Default: regex that matches nothing (impossible regex)
      exclude: ~r/(?!x)x/
    )
  end

  @impl true
  def configure(opts) do
    config = struct!(Config, opts)

    case File.ls(config.path) do
      {:ok, _} ->
        config

      {:error, err} ->
        msg = :inet.format_error(err)
        raise "Error configuring indexer for #{config.path}: #{msg}"
    end
  end

  @impl true
  def latest(config, count) do
    list_files(config.path, config.include, config.exclude)
    |> Enum.map(&with_unix_mtime/1)
    |> Enum.sort_by(fn {p, mtime} -> {mtime, p} end)
    |> Enum.take(-count)
    |> Enum.map(fn {p, _} -> p end)
  end
end
