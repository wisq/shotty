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
    |> then(fn {_mtime, files} -> files end)
  end

  # First directory:
  defp take_latest_reduce(count, dir_mtime, nil) do
    take_latest_reduce(count, dir_mtime, {unix_now(), []})
  end

  # Additional directories:
  defp take_latest_reduce(count, {dir, dir_mtime}, {oldest_mtime, files} = accum) do
    cond do
      Enum.count(files) < count ->
        take_latest_reduce_more(count, dir, accum)

      dir_mtime >= oldest_mtime ->
        take_latest_reduce_more(count, dir, accum)

      true ->
        {:halt, accum}
    end
  end

  defp take_latest_reduce_more(count, dir, {o_mt, previous_files}) do
    list_files(dir, ~r/^\d+_\d+\.jpg$/)
    |> Enum.concat(previous_files)
    |> Enum.sort_by(fn f -> {Path.basename(f), f} end)
    |> Enum.take(-count)
    |> then(fn files ->
      {:cont, {oldest_mtime(o_mt, files, previous_files), files}}
    end)
  end

  defp oldest_mtime(mt, [], _), do: mt
  defp oldest_mtime(mt, [f | _], [f | _]), do: mt
  defp oldest_mtime(_, [f | _], _), do: unix_mtime(f)
end
