defmodule Shotty.Indexer.Common do
  def list_files(path, filter) when is_function(filter) do
    File.ls!(path)
    |> Enum.reduce([], fn base, accum ->
      full = Path.join(path, base)

      case filter.(base, full) do
        true -> [full | accum]
        false -> accum
      end
    end)
  end

  def list_files(path, %Regex{} = include) do
    list_files(path, fn base, _full -> base =~ include end)
  end

  def list_files(path, %Regex{} = include, %Regex{} = exclude) do
    list_files(path, fn base, _full ->
      base =~ include && !(base =~ exclude)
    end)
  end

  def list_files_sorted(path, sorter) when is_function(sorter) do
    File.ls!(path)
    |> Enum.reduce([], fn base, accum ->
      full = Path.join(path, base)

      case sorter.(base, full) do
        {:sort_by, sort_key} -> [{sort_key, full} | accum]
        :skip -> accum
      end
    end)
    |> Enum.sort()
    |> Enum.map(fn {_, file} -> file end)
  end

  def unix_now do
    System.os_time(:second)
  end

  def unix_mtime(path) do
    File.stat!(path, time: :posix).mtime
  end

  def with_unix_mtime(path) do
    {path, unix_mtime(path)}
  end
end
