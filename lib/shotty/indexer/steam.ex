defmodule Shotty.Indexer.Steam do
  @behaviour Shotty.Indexer

  import Shotty.Indexer.Common

  @impl true
  def configure(opts) do
    Keyword.fetch!(opts, :path)
  end

  @impl true
  def latest(userdata_path, count) do
    userdata_path
    |> screenshot_paths()
    |> Enum.map(&with_unix_mtime/1)
    |> Enum.sort_by(fn {p, mtime} -> {0 - mtime, p} end)
    |> take_latest_files(count)
    |> Enum.take(count)
  end

  defp screenshot_paths(path) do
    if Path.join(path, "760") |> File.dir?() do
      user_screenshot_paths(path)
    else
      list_dirs(path, ~r/^\d+$/)
      |> Enum.flat_map(&user_screenshot_paths/1)
    end
  end

  defp user_screenshot_paths(path) do
    [path, "760", "remote"]
    |> Path.join()
    |> list_dirs(~r/^\d+$/)
    |> Enum.map(&Path.join(&1, "screenshots"))
  end

  defp list_dirs(path, regex) do
    list_files(path, fn base, full ->
      base =~ regex && File.dir?(full)
    end)
  end

  defp take_latest_files(dir_mtimes, count) do
    dir_mtimes
    |> Enum.reduce_while(nil, &take_latest_reduce(count, &1, &2))
  end

  # First directory:
  defp take_latest_reduce(count, {dir, _}, nil) do
    take_latest_reduce_more(count, dir, [])
  end

  # Additional directories:
  defp take_latest_reduce(count, {dir, dir_mtime}, [oldest_file | _] = accum) do
    cond do
      Enum.count(accum) < count ->
        take_latest_reduce_more(count, dir, accum)

      dir_mtime >= unix_mtime(oldest_file) ->
        take_latest_reduce_more(count, dir, accum)

      true ->
        {:halt, accum}
    end
  end

  defp take_latest_reduce_more(count, dir, accum) do
    {:cont,
     list_files(dir, ~r/^\d+_\d+\.jpg$/)
     |> Enum.concat(accum)
     |> Enum.sort_by(fn f -> {Path.basename(f), f} end)
     |> Enum.take(-count)}
  end
end
