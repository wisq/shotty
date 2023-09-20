defmodule Shotty.RouterTest do
  # Can be async as long as nothing else is calling Shotty.Fetcher.
  # (This means the Shotty.Fetcher tests must specify a different `name` option.)
  use ExUnit.Case, async: true
  use Plug.Test

  alias Shotty.Test.MockFetcher

  describe "when fetching the latest image" do
    test "succeeds" do
      {file_paths, file_data} = generate_files(1)
      mock(fn "path", 1 -> {:ok, file_paths} end)

      conn = get("/path/1")
      assert {"content-type", "application/zip"} in conn.resp_headers
      assert zip_contents(conn.resp_body) == file_data
    end

    test "handles no images available" do
      mock(fn "path", 1 -> {:ok, []} end)

      conn = get("/path/1")
      assert conn.status == 404
      assert conn.resp_body == "no file at that index"
    end

    test "sets zip entry mtime to file mtime" do
      {[file_path], _} = generate_files(1)
      mock(fn "path", 1 -> {:ok, [file_path]} end)

      old_mtime = System.os_time(:second) - Enum.random(1..1_000_000)
      File.touch!(file_path, old_mtime)

      conn = get("/path/1")
      {:ok, unzip_dir} = unzip(conn.resp_body)
      unzip_file = Path.join(unzip_dir, Path.basename(file_path))

      assert {:ok, %File.Stat{mtime: new_mtime}} = File.stat(unzip_file, time: :posix)
      assert_in_delta old_mtime, new_mtime, 1
    end
  end

  describe "when fetching a specific image index" do
    test "succeeds" do
      {file_paths, file_data} = generate_files(4)
      mock(fn "path", 4 -> {:ok, file_paths} end)

      conn = get("/path/4")
      assert {"content-type", "application/zip"} in conn.resp_headers
      assert zip_contents(conn.resp_body) == [List.first(file_data)]
    end

    test "handles not enough images available" do
      {file_paths, _file_data} = generate_files(3)
      mock(fn "path", 4 -> {:ok, file_paths} end)

      conn = get("/path/4")
      assert conn.status == 404
      assert conn.resp_body == "no file at that index"
    end
  end

  describe "when fetching a range of images" do
    test "succeeds" do
      {file_paths, file_data} = generate_files(8)
      mock(fn "path", 8 -> {:ok, file_paths} end)

      conn = get("/path/5..8")
      assert {"content-type", "application/zip"} in conn.resp_headers
      # Of the eight images returned by Fetcher,
      # we want the four oldest ones, i.e. the first four.
      assert zip_contents(conn.resp_body) == Enum.take(file_data, 4)
    end

    test "handles only some images available" do
      {file_paths, file_data} = generate_files(6)
      mock(fn "path", 8 -> {:ok, file_paths} end)

      conn = get("/path/5..8")
      assert {"content-type", "application/zip"} in conn.resp_headers
      assert zip_contents(conn.resp_body) == Enum.take(file_data, 2)
    end

    test "handles not enough images available" do
      {file_paths, _file_data} = generate_files(3)
      mock(fn "path", 8 -> {:ok, file_paths} end)

      conn = get("/path/6..8")
      assert conn.status == 404
      assert conn.resp_body == "no file at that index"
    end
  end

  @router Shotty.Router.init([])

  defp get(url) do
    conn(:get, url)
    |> Shotty.Router.call(@router)
  end

  defp mock(handler) do
    {:ok, _pid} = start_supervised({MockFetcher, handler})
  end

  defp generate_files(count) do
    {:ok, dir} = Briefly.create(directory: true)

    1..count
    |> Enum.map(fn _ ->
      file = "#{System.os_time()}.png"
      path = Path.join(dir, file)
      data = :rand.bytes(10)
      File.write!(path, data)

      {path, {file, data}}
    end)
    |> Enum.unzip()
  end

  defmodule ZipState do
    defstruct(
      files: [],
      entry: nil,
      data: []
    )
  end

  defp unzip(zip_data) do
    {:ok, zip_file} = Briefly.create()
    File.write!(zip_file, zip_data)

    {:ok, unzip_dir} = Briefly.create(directory: true)
    System.cmd("unzip", [zip_file], cd: unzip_dir, env: [{"TZ", "UTC"}])

    {:ok, unzip_dir}
  end

  defp zip_contents(zip_data) do
    {:ok, unzip_dir} = unzip(zip_data)

    File.ls!(unzip_dir)
    |> Enum.sort()
    |> Enum.map(fn file ->
      path = Path.join(unzip_dir, file)
      data = File.read!(path)
      {file, data}
    end)
  end
end
