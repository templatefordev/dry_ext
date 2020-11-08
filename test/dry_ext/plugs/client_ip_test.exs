defmodule DryExt.Plugs.ClientIpTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Plug.Test

  alias DryExt.Plugs.ClientIp

  @client_ip "37.214.25.229"
  @forwarded_ips "37.214.25.229, 112.215.25.228"

  test "not assigns client ip if empty header" do
    conn =
      conn(:get, "/")
      |> ClientIp.call([])

    assert conn.assigns[:client_ip] == nil
  end

  test "not assigns client ip if exists already" do
    assign_ip = "50.25.15.10"

    conn =
      conn(:get, "/")
      |> put_req_header("x-real-ip", @client_ip)
      |> assign(:client_ip, assign_ip)
      |> ClientIp.call([])

    assert conn.assigns.client_ip == assign_ip
  end

  test "assigns client_ip from x-real-ip" do
    conn =
      conn(:get, "/")
      |> put_req_header("x-real-ip", @client_ip)
      |> put_req_header("x-client-ip", "125.112.25.15")
      |> ClientIp.call([])

    assert conn.assigns.client_ip == "37.214.25.229"
  end

  test "assigns client_ip from x-client-ip" do
    conn =
      conn(:get, "/")
      |> put_req_header("x-client-ip", @client_ip)
      |> put_req_header("x-forwarded-for", @forwarded_ips)
      |> ClientIp.call([])

    assert conn.assigns.client_ip == "37.214.25.229"
  end

  describe "assigns client_ip from x-forwarded-for" do
    test "when valid ips" do
      conn =
        conn(:get, "/")
        |> put_req_header("x-forwarded-for", @forwarded_ips)
        |> ClientIp.call([])

      assert conn.assigns.client_ip == "37.214.25.229"
    end

    test "when first ip is private" do
      conn =
        conn(:get, "/")
        |> put_req_header("x-forwarded-for", "127.0.0.1," <> @forwarded_ips)
        |> ClientIp.call([])

      assert conn.assigns.client_ip == "37.214.25.229"

      conn =
        conn(:get, "/")
        |> put_req_header("x-forwarded-for", "100.64.0.1," <> @forwarded_ips)
        |> ClientIp.call([])

      assert conn.assigns.client_ip == "37.214.25.229"

      conn =
        conn(:get, "/")
        |> put_req_header("x-forwarded-for", "172.16.0.1," <> @forwarded_ips)
        |> ClientIp.call([])

      assert conn.assigns.client_ip == "37.214.25.229"

      conn =
        conn(:get, "/")
        |> put_req_header("x-forwarded-for", "192.168.0.1," <> @forwarded_ips)
        |> ClientIp.call([])

      assert conn.assigns.client_ip == "37.214.25.229"
    end

    test "when first ip is unknown" do
      conn =
        conn(:get, "/")
        |> put_req_header("x-forwarded-for", "unknown," <> @forwarded_ips)
        |> ClientIp.call([])

      assert conn.assigns.client_ip == "37.214.25.229"
    end

    test "when first ip is empty" do
      conn =
        conn(:get, "/")
        |> put_req_header("x-forwarded-for", " ," <> @forwarded_ips)
        |> ClientIp.call([])

      assert conn.assigns.client_ip == "37.214.25.229"
    end
  end
end
