defmodule DryExt.Plugs.SetReferralCookieTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias DryExt.Plugs.SetReferralCookie

  @secret String.duplicate("abcdef0123456789", 8)

  @config_opts [max_age: 60 * 60 * 24, domain: "example.com"]
  @default_key "_dry_ext_ref_key"
  @default_max_age 60 * 60 * 24 * 365

  @default_opts SetReferralCookie.init([])

  defp sign_conn(conn, secret \\ @secret) do
    put_in(conn.secret_key_base, secret)
    |> fetch_query_params
    |> fetch_cookies
  end

  setup do
    on_exit(fn ->
      Application.put_env(:dry_ext, :referral_cookie, [])
    end)
  end

  test "return default opts" do
    assert @default_opts == [sign: true, max_age: @default_max_age]
  end

  test "return config opts" do
    Application.put_env(:dry_ext, :referral_cookie, @config_opts)
    opts = SetReferralCookie.init([])

    assert opts == [sign: true] ++ @config_opts
  end

  test "sets cookie key from config opts" do
    key = "_test_ref_key"
    config = @config_opts ++ [key: key]
    Application.put_env(:dry_ext, :referral_cookie, config)
    opts = SetReferralCookie.init([])

    conn =
      conn(:get, "/item?ref=asdf")
      |> sign_conn()
      |> SetReferralCookie.call(opts)

    conn =
      conn(:get, "/item")
      |> recycle_cookies(conn)
      |> sign_conn()

    assert is_map_key(conn.cookies, key)
  end

  test "gets and sets signed referral cookie" do
    conn =
      conn(:get, "/item?ref=asdf")
      |> sign_conn()
      |> SetReferralCookie.call(@default_opts)

    ref_code =
      conn(:get, "/item")
      |> recycle_cookies(conn)
      |> sign_conn()
      |> fetch_cookies(signed: [@default_key])
      |> Map.from_struct()
      |> get_in([:cookies, @default_key, :ref_code])

    assert ref_code == "asdf"
  end

  test "redirect to root after set referral cookie" do
    conn =
      conn(:get, "/?ref=asdf")
      |> sign_conn()
      |> SetReferralCookie.call(@default_opts)

    assert get_resp_header(conn, "location") == ["/"]
    assert conn.status == 302
    assert conn.halted == true
  end

  test "redirect to path after set referral cookie" do
    conn =
      conn(:get, "/item?ref=asdf")
      |> sign_conn()
      |> SetReferralCookie.call(@default_opts)

    assert get_resp_header(conn, "location") == ["/item"]
    assert conn.status == 302
    assert conn.halted == true
  end

  describe "assign_referral_code/2 assign referral code from cookie" do
    test "when not exists cookie" do
      conn =
        conn(:get, "/")
        |> sign_conn()
        |> SetReferralCookie.assign_referral_code([])

      assert conn.assigns[:referral_code] == nil
    end

    test "when exists cookie" do
      conn =
        conn(:get, "/?ref=asdf")
        |> sign_conn()
        |> SetReferralCookie.call(@default_opts)

      conn =
        conn(:get, "/")
        |> recycle_cookies(conn)
        |> sign_conn()
        |> SetReferralCookie.assign_referral_code([])

      assert conn.assigns.referral_code == "asdf"
    end
  end
end
