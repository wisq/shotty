defmodule Shotty.Indexer.Sorted do
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
    list_files_sorted(config.path, fn base, _full ->
      if base =~ config.include && !(base =~ config.exclude) do
        {:sort_by, base}
      else
        :skip
      end
    end)
    |> Enum.take(-count)
  end
end
