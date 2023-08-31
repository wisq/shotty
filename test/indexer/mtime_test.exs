defmodule Shotty.Indexer.MtimeTest do
  use ExUnit.Case, async: true

  alias Shotty.Indexer.Mtime

  setup do
    {:ok, path} = Briefly.create(directory: true)
    [path: path]

    files =
      Stream.zip([1..15, extension_stream(), mtime_stream()])
      |> Enum.map(fn {_, ext, mtime} ->
        base = :crypto.hash(:md5, "#{mtime}") |> Base.encode16(case: :lower)
        file = Path.join(path, "#{base}.#{ext}")
        File.touch!(file, mtime)
        file
      end)
      |> Enum.reverse()

    [path: path, files: files]
  end

  test "finds the most recent file", %{path: path, files: files} do
    config = Mtime.configure(path: path)
    assert Mtime.latest(config, 1) == Enum.take(files, -1)
  end

  test "finds the five most recent files", %{path: path, files: files} do
    config = Mtime.configure(path: path)
    assert Mtime.latest(config, 5) == Enum.take(files, -5)
  end

  test "finds the most recent PNG", %{path: path, files: files} do
    pngs = files |> Enum.filter(&String.ends_with?(&1, ".png"))
    config = Mtime.configure(path: path, include: ~r/\.png$/)
    assert Mtime.latest(config, 1) == Enum.take(pngs, -1)
  end

  test "finds the three most recent JPGs", %{path: path, files: files} do
    pngs = files |> Enum.filter(&String.ends_with?(&1, ".jpg"))
    config = Mtime.configure(path: path, include: ~r/\.jpg$/)
    assert Mtime.latest(config, 3) == Enum.take(pngs, -3)
  end

  test "finds the three most recent non-TXTs", %{path: path, files: files} do
    pngs = files |> Enum.reject(&String.ends_with?(&1, ".txt"))
    config = Mtime.configure(path: path, exclude: ~r/\.txt$/)
    assert Mtime.latest(config, 3) == Enum.take(pngs, -3)
  end

  test "finds the second most recent PNG, using excludes", %{path: path, files: files} do
    pngs = files |> Enum.filter(&String.ends_with?(&1, ".png"))
    most_recent = Enum.at(pngs, -1) |> Path.basename(".png")
    assert most_recent =~ ~r/^[0-9a-f]+$/

    config = Mtime.configure(path: path, include: ~r/\.png$/, exclude: ~r/#{most_recent}/)
    assert Mtime.latest(config, 1) == [Enum.at(pngs, -2)]
  end

  defp extension_stream do
    extensions = ~w(png jpg txt)

    Stream.resource(
      fn -> nil end,
      fn nil -> {Enum.shuffle(extensions), nil} end,
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
