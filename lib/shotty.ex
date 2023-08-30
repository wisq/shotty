defmodule Shotty do
  use Application
  require Logger

  def start(_type, _args) do
    children =
      if Application.get_env(:shotty, :start, true) do
        app_children()
      else
        []
      end

    opts = [strategy: :one_for_one, name: Shotty.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp app_children do
    {ip, port} = Application.fetch_env!(:shotty, :bind)
    paths = Application.get_env(:shotty, :paths, [])

    [
      {Shotty.Fetcher, paths: paths},
      {Bandit, plug: Shotty.Router, ip: parse_ip(ip), port: port}
    ]
  end

  defp parse_ip(ip) when is_tuple(ip) do
    case :inet.is_ip_address(ip) do
      true -> ip
      false -> raise "Not an IP address: #{inspect(ip)}"
    end
  end

  defp parse_ip(s) when is_binary(s), do: s |> String.to_charlist() |> parse_ip()

  defp parse_ip(c) when is_list(c) do
    case :inet.parse_address(c) do
      {:ok, ip} -> ip
      {:error, err} -> raise "Got #{inspect(err)} parsing IP #{inspect(c)}"
    end
  end
end
