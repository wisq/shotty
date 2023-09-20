defmodule Shotty.Router do
  use Plug.Router
  require Logger
  alias Shotty.Fetcher

  plug(:match)
  plug(:dispatch)

  get "/:path/:range" do
    case String.split(range, "..", parts: 2) do
      [index] -> get_files(conn, path, index, index)
      [min, max] -> get_files(conn, path, min, max)
    end
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  defp get_files(conn, path, min_str, max_str) do
    with {:ok, min} <- parse_int(min_str),
         {:ok, max} <- parse_int(max_str),
         {:ok, files} <- Fetcher.fetch(path, min..max) do
      conn
      |> put_resp_header("content-type", "application/zip")
      |> send_chunked(200)
      |> send_files(files)
    else
      {:error, err} ->
        {code, msg} = error_message(err)
        send_resp(conn, code, msg)
    end
  end

  defp send_files(conn, files) do
    zip_stream(files)
    |> Enum.reduce_while(conn, fn chunk, conn ->
      case Plug.Conn.chunk(conn, chunk) do
        {:ok, conn} ->
          {:cont, conn}

        {:error, :closed} ->
          {:halt, conn}
      end
    end)
  end

  defp zip_stream(files) do
    files
    |> Enum.map(fn file ->
      {:ok, %File.Stat{mtime: mtime}} = File.stat(file, time: :posix)

      Zstream.entry(
        Path.basename(file),
        File.stream!(file, [], 4096),
        mtime: DateTime.from_unix!(mtime)
      )
    end)
    |> Zstream.zip()
  end

  defp parse_int(str) do
    case Integer.parse(str) do
      {int, ""} -> {:ok, int}
      :error -> {:error, "not an integer: #{str}"}
      {_, rest} -> {:error, "not an integer: #{str} (at #{inspect(rest)})"}
    end
  end

  defp error_message(str) when is_binary(str), do: {400, str}
  defp error_message(:index_not_found), do: {404, "no file at that index"}

  defp error_message(err) do
    Logger.error("Unknown error: #{err}")
    {400, "unknown error"}
  end
end
