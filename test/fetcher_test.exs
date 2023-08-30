defmodule Shotty.FetcherTest do
  # Note that MockFetcherTest (not used here) steals the `Shotty.Fetcher` name,
  # so in order to be `async: true`, all tests here must avoid using that name.
  use ExUnit.Case, async: true

  alias Shotty.Fetcher

  defmodule MockIndexer do
    @behaviour Shotty.Indexer

    @impl true
    def configure(opts) do
      {pid, opts} = Keyword.pop!(opts, :pid)
      send(pid, {:configure, opts})
      {:config, opts, pid}
    end

    @impl true
    def latest({:config, opts, pid}, count) do
      case Keyword.fetch(opts, :handler) do
        {:ok, fun} ->
          fun.(count, opts)

        :error ->
          send(pid, {:latest, count, opts})
          1..count |> Enum.map(fn n -> "file#{n}.png" end)
      end
    end
  end

  test "configures indexers on start" do
    {:ok, _pid} = start_fetcher(path1: [p: 1], path2: [p: 2])

    assert_received {:configure, p: 1}
    assert_received {:configure, p: 2}
  end

  test "fetches images from relevant indexer" do
    {:ok, pid} = start_fetcher(path1: [p: 1], path2: [p: 2])

    assert Fetcher.fetch("path1", 5, pid) == {:ok, "file1.png"}
    assert Fetcher.fetch("path2", 3, pid) == {:ok, "file1.png"}

    assert_received {:latest, 5, p: 1}
    assert_received {:latest, 3, p: 2}
  end

  describe "when fetching the latest image" do
    test "succeeds" do
      handler = fn 1, _opts -> ["latest.png"] end
      {:ok, pid} = start_fetcher(path: [handler: handler])
      assert Fetcher.fetch("path", 1, pid) == {:ok, "latest.png"}
    end

    test "handles no files available" do
      handler = fn 1, _opts -> [] end
      {:ok, pid} = start_fetcher(path: [handler: handler])
      assert Fetcher.fetch("path", 1, pid) == {:error, :index_not_found}
    end
  end

  describe "when fetching an older image" do
    test "succeeds" do
      handler = fn 3, _opts -> ~w{101.png 102.png 103.png} end
      {:ok, pid} = start_fetcher(path: [handler: handler])
      assert Fetcher.fetch("path", 3, pid) == {:ok, "101.png"}
    end

    test "handles not enough files available" do
      handler = fn 3, _opts -> ~w{201.png 202.png} end
      {:ok, pid} = start_fetcher(path: [handler: handler])
      assert Fetcher.fetch("path", 3, pid) == {:error, :index_not_found}
    end
  end

  describe "when fetching a range of images" do
    test "succeeds" do
      handler = fn 6, _opts -> ~w{301.png 302.png 303.png 304.png 305.png 306.png} end
      {:ok, pid} = start_fetcher(path: [handler: handler])
      assert Fetcher.fetch("path", 4..6, pid) == {:ok, ~w{301.png 302.png 303.png}}
    end

    test "handles fewer files available than requested" do
      handler = fn 6, _opts -> ~w{301.png 302.png 303.png 304.png 305.png} end
      {:ok, pid} = start_fetcher(path: [handler: handler])
      assert Fetcher.fetch("path", 4..6, pid) == {:ok, ~w{301.png 302.png}}
    end

    test "handles not enough files available" do
      handler = fn 6, _opts -> ~w{301.png 302.png} end
      {:ok, pid} = start_fetcher(path: [handler: handler])
      assert Fetcher.fetch("path", 4..6, pid) == {:error, :index_not_found}
    end
  end

  defp start_fetcher(paths) do
    paths =
      Enum.map(paths, fn {name, opts} ->
        opts
        |> Keyword.put_new(:indexer, MockIndexer)
        |> Keyword.put_new(:pid, self())
        |> then(&{name, &1})
      end)

    start_supervised({Fetcher, paths: paths, name: nil})
  end
end
