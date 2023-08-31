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
      case Regex.named_captures(config.include, base) do
        %{"sort" => key} -> {:sort_by, key}
        %{"sort_integer" => n} -> {:sort_by, String.to_integer(n)}
        %{} -> {:sort_by, base}
        nil -> :skip
      end
      |> then(fn
        {:sort_by, _} = rval -> if base =~ config.exclude, do: :skip, else: rval
        :skip -> :skip
      end)
    end)
    |> Enum.take(-count)
  end
end
