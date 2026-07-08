defmodule Shotty.Indexer.Mtime do
  @behaviour Shotty.Indexer

  import Shotty.Indexer.Common

  defmodule Config do
    @enforce_keys [:path, :include, :exclude]
    defstruct(@enforce_keys)

    def new(opts) do
      opts
      # Default: regex that matches anything
      |> Keyword.put_new(:include, ~r//)
      # Default: regex that matches nothing (impossible regex)
      |> Keyword.put_new(:exclude, ~r/(?!x)x/)
      |> then(&struct!(Config, &1))
    end
  end

  @impl true
  def configure(opts) do
    config = Config.new(opts)

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
