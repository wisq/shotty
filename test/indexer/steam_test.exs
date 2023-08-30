defmodule Shotty.Indexer.SteamTest do
  use ExUnit.Case, async: true

  alias Shotty.Indexer.Steam

  describe "given a single user's screenshots" do
    setup do
      {:ok, path} = Briefly.create(directory: true)
      file_mtimes = create_random_screenshots(path)

      [
        path: path,
        files: file_mtimes |> Enum.map(fn {f, _} -> f end)
      ]
    end

    test "finds the most recent screenshot", %{path: path, files: files} do
      assert Steam.latest(path, 1) == Enum.take(files, -1)
    end

    test "finds the five most recent screenshots", %{path: path, files: files} do
      assert Steam.latest(path, 5) == Enum.take(files, -5)
    end
  end

  describe "given several users' screenshots" do
    setup do
      {:ok, path} = Briefly.create(directory: true)

      user_count = pick_one(3..5)

      file_mtimes =
        1..user_count
        |> Enum.flat_map(fn _ ->
          dir = Enum.random(1..1_000_000) |> Integer.to_string()
          Path.join(path, dir) |> create_random_screenshots()
        end)
        |> Enum.sort_by(fn {f, mt} -> {mt, f} end)

      [
        path: path,
        files: file_mtimes |> Enum.map(fn {f, _} -> f end)
      ]
    end

    test "finds the most recent screenshot", %{path: path, files: files} do
      assert Steam.latest(path, 1) == Enum.take(files, -1)
    end

    test "finds the ten most recent screenshots", %{path: path, files: files} do
      assert Steam.latest(path, 10) == Enum.take(files, -10)
    end
  end

  defp create_random_screenshots(root, opts \\ []) do
    game_count = Keyword.get(opts, :game_count, 3..5) |> pick_one()
    batch_count = Keyword.get(opts, :batch_count, 5..10) |> pick_one()
    batch_sizes = Keyword.get(opts, :batch_size, 1..3) |> pick_many(batch_count)

    path = Path.join([root, "760", "remote"])

    batch_sizes
    |> Enum.zip(game_dir_stream(path, game_count))
    |> Enum.flat_map(fn {count, dir} -> List.duplicate(dir, count) end)
    |> Enum.zip(mtime_stream())
    |> Enum.reverse()
    |> Enum.map(fn {dir, mtime} ->
      filename = DateTime.from_unix!(mtime) |> Calendar.strftime("%Y%m%d%H%M%S_1.jpg")
      file = Path.join(dir, filename)

      File.touch!(file, mtime)
      File.touch!(dir, mtime)

      {file, mtime}
    end)
  end

  defp pick_one(n) when is_integer(n), do: n
  defp pick_one(_.._ = r), do: Enum.random(r)

  defp pick_many(nr, count) do
    1..count
    |> Enum.map(fn _ -> pick_one(nr) end)
  end

  defp game_dir_stream(path, count) do
    game_dirs =
      1..count
      |> Enum.map(fn _ ->
        dir = Enum.random(1..1_000_000) |> Integer.to_string()
        Path.join([path, dir, "screenshots"])
      end)

    game_dirs |> Enum.each(&File.mkdir_p!/1)

    Stream.resource(
      fn -> nil end,
      fn nil -> {Enum.shuffle(game_dirs), nil} end,
      fn nil -> nil end
    )
  end

  defp mtime_stream do
    Stream.resource(
      fn -> System.os_time(:second) - Enum.random(1..5) end,
      fn t -> {[t], t - Enum.random(1..60)} end,
      fn _ -> nil end
    )
  end
end
