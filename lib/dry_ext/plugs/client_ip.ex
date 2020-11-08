defmodule DryExt.Plugs.ClientIp do
  @moduledoc """
  A plug to assign `client_ip` address of request
  from `x-real-ip` or `x-client-ip` or `x-forwarded-for` header
  and without rewrite standard remote_ip field
  """

  @behaviour Plug

  alias Plug.Conn

  import Plug.Conn, only: [assign: 3, get_req_header: 2]

  require Logger

  @spec init(any) :: []
  def init(_opts), do: []

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(%Conn{assigns: %{client_ip: _}} = conn, _opts), do: conn

  def call(conn, _opts) do
    real_ip = get_req_header(conn, "x-real-ip")
    client_ip = get_req_header(conn, "x-client-ip")
    forwarded_ips = get_req_header(conn, "x-forwarded-for")

    cond do
      real_ip != [] ->
        [ip | _] = real_ip
        Logger.debug(fn -> assign_real_ip_msg(ip) end)
        assign(conn, :client_ip, ip)

      client_ip != [] ->
        [ip | _] = client_ip
        Logger.debug(fn -> assign_client_ip_msg(ip) end)
        assign(conn, :client_ip, ip)

      true ->
        process(conn, forwarded_ips)
    end
  end

  defp process(conn, []), do: conn

  defp process(conn, [ips | _]) do
    filtered_ips =
      ips
      |> String.split(~r{\s*,\s*}, trim: true)
      |> Enum.filter(&(&1 != "unknown"))
      |> Enum.map(&hd(String.split(&1, ":")))
      |> Enum.filter(&(&1 != ""))
      |> Enum.map(&parse_address(&1))
      |> Enum.filter(&public_ip?(&1))

    case filtered_ips do
      [] ->
        conn

      [ip | _] ->
        client_ip = ip |> :inet.ntoa() |> to_string()
        Logger.debug(fn -> assign_forwarded_ip_msg(client_ip, ips) end)
        assign(conn, :client_ip, client_ip)
    end
  end

  @spec parse_address(String.t()) :: :inet.ip_address()
  defp parse_address(ip) do
    case :inet.parse_ipv4strict_address(to_charlist(ip)) do
      {:ok, ip_address} -> ip_address
      {:error, :einval} -> :einval
    end
  end

  # http://en.wikipedia.org/wiki/Private_network
  @spec public_ip?(:inet.ip_address() | atom) :: boolean
  defp public_ip?({10, _, _, _}), do: false
  defp public_ip?({100, second, _, _}) when second >= 64 and second <= 127, do: false
  defp public_ip?({172, second, _, _}) when second >= 16 and second <= 31, do: false
  defp public_ip?({192, 168, _, _}), do: false
  defp public_ip?({127, 0, 0, _}), do: false
  defp public_ip?({_, _, _, _}), do: true
  defp public_ip?(:einval), do: false

  defp assign_real_ip_msg(ip) do
    [inspect(__MODULE__), " assinged client_ip: ", inspect(ip), " from 'x-real-ip'"]
  end

  defp assign_client_ip_msg(ip) do
    [inspect(__MODULE__), " assinged client_ip: ", inspect(ip), " from 'x-client-ip'"]
  end

  defp assign_forwarded_ip_msg(ip, forwarded_ips) do
    [
      inspect(__MODULE__),
      " assinged client_ip: ",
      inspect(ip),
      " from 'x-forwarded-for': ",
      inspect(forwarded_ips)
    ]
  end
end
