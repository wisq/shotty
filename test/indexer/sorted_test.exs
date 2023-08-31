defmodule Shotty.Indexer.SortedTest do
  use ExUnit.Case, async: true

  alias Shotty.Indexer.Sorted

  describe "using default filename ordering" do
    setup do
      {:ok, path} = Briefly.create(directory: true)
      [path: path]

      files =
        1..15
        |> Stream.zip(extension_stream())
        |> Enum.map(fn {_, ext} ->
          base = random_alphanumeric(10)
          file = Path.join(path, "#{base}.#{ext}")
          File.touch(file, System.os_time(:second) - Enum.random(1..86400))
          file
        end)
        |> Enum.sort()

      [path: path, files: files]
    end

    test "finds the most recent file", %{path: path, files: files} do
      config = Sorted.configure(path: path)
      assert Sorted.latest(config, 1) == Enum.take(files, -1)
    end

    test "finds the five most recent files", %{path: path, files: files} do
      config = Sorted.configure(path: path)
      assert Sorted.latest(config, 5) == Enum.take(files, -5)
    end

    test "finds the most recent PNG", %{path: path, files: files} do
      pngs = files |> Enum.filter(&String.ends_with?(&1, ".png"))
      config = Sorted.configure(path: path, include: ~r/\.png$/)
      assert Sorted.latest(config, 1) == Enum.take(pngs, -1)
    end

    test "finds the three most recent JPGs", %{path: path, files: files} do
      pngs = files |> Enum.filter(&String.ends_with?(&1, ".jpg"))
      config = Sorted.configure(path: path, include: ~r/\.jpg$/)
      assert Sorted.latest(config, 3) == Enum.take(pngs, -3)
    end

    test "finds the three most recent non-TXTs", %{path: path, files: files} do
      pngs = files |> Enum.reject(&String.ends_with?(&1, ".txt"))
      config = Sorted.configure(path: path, exclude: ~r/\.txt$/)
      assert Sorted.latest(config, 3) == Enum.take(pngs, -3)
    end

    test "finds the second most recent PNG, using excludes", %{path: path, files: files} do
      pngs = files |> Enum.filter(&String.ends_with?(&1, ".png"))
      most_recent = Enum.at(pngs, -1) |> Path.basename(".png")
      assert most_recent =~ ~r/^[0-9a-z]+$/

      config = Sorted.configure(path: path, include: ~r/\.png$/, exclude: ~r/#{most_recent}/)
      assert Sorted.latest(config, 1) == [Enum.at(pngs, -2)]
    end
  end

  describe "using a custom sort key" do
    setup do
      {:ok, path} = Briefly.create(directory: true)
      [path: path]

      files =
        1..15
        |> Enum.map(fn _ -> random_alphanumeric(5) end)
        |> Enum.sort()
        |> Stream.zip(extension_stream())
        |> Enum.map(fn {key, ext} ->
          prefix = random_alphanumeric(5)
          file = Path.join(path, "#{prefix}-#{key}.#{ext}")
          File.touch(file, System.os_time(:second) - Enum.random(1..86400))
          file
        end)

      [path: path, files: files]
    end

    @sort_regex ~r/^.{5}-(?<sort>.{5})\./
    @sort_regex_png ~r/^.{5}-(?<sort>.{5})\.png$/
    @sort_regex_jpg ~r/^.{5}-(?<sort>.{5})\.jpg$/

    test "finds the most recent file", %{path: path, files: files} do
      config = Sorted.configure(path: path, include: @sort_regex)
      assert Sorted.latest(config, 1) == Enum.take(files, -1)
    end

    test "finds the five most recent files", %{path: path, files: files} do
      config = Sorted.configure(path: path, include: @sort_regex)
      assert Sorted.latest(config, 5) == Enum.take(files, -5)
    end

    test "finds the most recent PNG", %{path: path, files: files} do
      pngs = files |> Enum.filter(&String.ends_with?(&1, ".png"))
      config = Sorted.configure(path: path, include: @sort_regex_png)
      assert Sorted.latest(config, 1) == Enum.take(pngs, -1)
    end

    test "finds the three most recent JPGs", %{path: path, files: files} do
      pngs = files |> Enum.filter(&String.ends_with?(&1, ".jpg"))
      config = Sorted.configure(path: path, include: @sort_regex_jpg)
      assert Sorted.latest(config, 3) == Enum.take(pngs, -3)
    end

    test "finds the three most recent non-TXTs", %{path: path, files: files} do
      pngs = files |> Enum.reject(&String.ends_with?(&1, ".txt"))
      config = Sorted.configure(path: path, include: @sort_regex, exclude: ~r/\.txt$/)
      assert Sorted.latest(config, 3) == Enum.take(pngs, -3)
    end

    test "finds the second most recent PNG, using excludes", %{path: path, files: files} do
      pngs = files |> Enum.filter(&String.ends_with?(&1, ".png"))
      most_recent = Enum.at(pngs, -1) |> Path.basename(".png")
      assert most_recent =~ ~r/^[0-9a-z-]+$/

      config = Sorted.configure(path: path, include: @sort_regex_png, exclude: ~r/#{most_recent}/)
      assert Sorted.latest(config, 1) == [Enum.at(pngs, -2)]
    end
  end

  describe "using an integer sort key" do
    setup do
      {:ok, path} = Briefly.create(directory: true)
      [path: path]

      files =
        1..20
        |> Enum.map(fn _ -> :rand.uniform(1_000_000) end)
        |> Enum.uniq()
        |> Enum.take(15)
        |> Enum.sort()
        |> Stream.zip(extension_stream())
        |> Enum.map(fn {key, ext} ->
          prefix = random_alphanumeric(5)
          file = Path.join(path, "#{prefix}-#{key}.#{ext}")
          File.touch(file, System.os_time(:second) - Enum.random(1..86400))
          file
        end)

      [path: path, files: files]
    end

    @integer_regex ~r/^.{5}-(?<sort_integer>\d+)\./
    @integer_regex_png ~r/^.{5}-(?<sort_integer>\d+)\.png$/
    @integer_regex_jpg ~r/^.{5}-(?<sort_integer>\d+)\.jpg$/

    test "finds the most recent file", %{path: path, files: files} do
      config = Sorted.configure(path: path, include: @integer_regex)
      assert Sorted.latest(config, 1) == Enum.take(files, -1)
    end

    test "finds the five most recent files", %{path: path, files: files} do
      config = Sorted.configure(path: path, include: @integer_regex)
      assert Sorted.latest(config, 5) == Enum.take(files, -5)
    end

    test "finds the most recent PNG", %{path: path, files: files} do
      pngs = files |> Enum.filter(&String.ends_with?(&1, ".png"))
      config = Sorted.configure(path: path, include: @integer_regex_png)
      assert Sorted.latest(config, 1) == Enum.take(pngs, -1)
    end

    test "finds the three most recent JPGs", %{path: path, files: files} do
      pngs = files |> Enum.filter(&String.ends_with?(&1, ".jpg"))
      config = Sorted.configure(path: path, include: @integer_regex_jpg)
      assert Sorted.latest(config, 3) == Enum.take(pngs, -3)
    end

    test "finds the three most recent non-TXTs", %{path: path, files: files} do
      pngs = files |> Enum.reject(&String.ends_with?(&1, ".txt"))
      config = Sorted.configure(path: path, include: @integer_regex, exclude: ~r/\.txt$/)
      assert Sorted.latest(config, 3) == Enum.take(pngs, -3)
    end

    test "finds the second most recent PNG, using excludes", %{path: path, files: files} do
      pngs = files |> Enum.filter(&String.ends_with?(&1, ".png"))
      most_recent = Enum.at(pngs, -1) |> Path.basename(".png")
      assert most_recent =~ ~r/^[0-9a-z-]+$/

      config =
        Sorted.configure(
          path: path,
          include: @integer_regex_png,
          exclude: ~r/#{most_recent}/
        )

      assert Sorted.latest(config, 1) == [Enum.at(pngs, -2)]
    end
  end

  defp extension_stream do
    extensions = ~w(png jpg txt)

    Stream.resource(
      fn -> nil end,
      fn nil -> {Enum.shuffle(extensions), nil} end,
      fn nil -> nil end
    )
  end

  @hex [?0..?9, ?a..?z] |> Enum.flat_map(&Enum.to_list/1)

  defp random_alphanumeric(chars) do
    1..chars
    |> Enum.map(fn _ -> Enum.random(@hex) end)
    |> String.Chars.to_string()
  end
end
