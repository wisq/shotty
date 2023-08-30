defmodule Shotty.Indexer.Steam do
  @behaviour Shotty.Indexer

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

  defp list_files(path, filter) when is_function(filter) do
    File.ls!(path)
    |> Enum.reduce([], fn base, accum ->
      full = Path.join(path, base)

      case filter.(base, full) do
        true -> [full | accum]
        false -> accum
      end
    end)
  end

  defp list_files(path, %Regex{} = regex) do
    list_files(path, fn base, _full -> base =~ regex end)
  end

  defp take_latest_files(dir_mtimes, count) do
    dir_mtimes
    |> Enum.reduce_while(nil, &take_latest_reduce(count, &1, &2))
    |> Enum.map(fn {f, _mt} -> f end)
  end

  # First directory:
  defp take_latest_reduce(count, {dir, _}, nil) do
    take_latest_reduce_more(count, dir, [])
  end

  # Additional directories, when directory is newer than (or same as) oldest file:
  defp take_latest_reduce(count, {dir, d_mt}, [{_f, f_mt} | _] = accum) when d_mt >= f_mt do
    take_latest_reduce_more(count, dir, accum)
  end

  # Additional directories, when directory is older than oldest file:
  defp take_latest_reduce(count, {dir, _}, [{_, _} | _] = accum) do
    if Enum.count(accum) >= count do
      {:halt, accum}
    else
      take_latest_reduce_more(count, dir, accum)
    end
  end

  defp take_latest_reduce_more(count, dir, accum) do
    {:cont,
     ls_file_mtimes(dir, count)
     |> Enum.concat(accum)
     |> Enum.sort_by(fn {f, mtime} -> {mtime, f} end)
     |> Enum.take(-count)}
  end

  defp ls_file_mtimes(dir, count) do
    list_files(dir, ~r/^\d+_\d+\.jpg$/)
    |> Enum.sort()
    |> Enum.reverse()
    |> Enum.take(count)
    |> Enum.map(&with_unix_mtime/1)
  end

  defp with_unix_mtime(path) do
    mtime = File.stat!(path, time: :posix).mtime
    {path, mtime}
  end
end
