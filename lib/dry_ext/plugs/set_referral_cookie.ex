defmodule DryExt.Plugs.SetReferralCookie do
  @moduledoc """
  The plug set referral cookie and redirect
  to root location if query params contains `?ref=SDIxl2U`.

  For example:

      defmodule MyAppWeb.Router do
        use Phoenix.Router

        pipeline :browser do
          plug :fetch_session
          plug :accepts, ["html"]

          # add this line
          plug DryExt.Plugs.SetReferralCookie
        end

        scope "/" do
          pipe_through :browser

          # browser related routes and resources
        end
      end

  Configuration:

      config :dry_ext, :referral_cookie,
        key: "_dry_ext_ref_key",
        sign: true,
        max_age: 60 * 60 * 24 * 365,
        domain: "example.com",

    Options:

      * `key` - optional(default "_dry_ext_ref_key"), name of cookie.
      * `sign` - optional(default true), when true, signs the cookie.
        And then `Plug.Conn.fetch_cookies(conn, signed: ~w(_dry_ext_ref_key))`.
      * `max_age` - optional(default 365 days),the cookie max-age, in seconds.
      * `domain` - optional, the domain the cookie applies to.
  """
  @behaviour Plug

  import Plug.Conn,
    only: [
      put_resp_cookie: 4,
      put_resp_header: 3,
      put_resp_content_type: 2,
      send_resp: 3,
      halt: 1
    ]

  @config_options Application.get_env(:dry_ext, :referral_cookie, [])

  @default_max_age 60 * 60 * 24 * 365
  @default_key "_dry_ext_ref_key"
  @default_sign true

  @defaults_opts [sign: @default_sign, max_age: @default_max_age, domain: nil]

  def init(opts), do: opts

  def call(%Plug.Conn{params: %{"ref" => ref_code}} = conn, _opts) do
    body = "<html><body>You are being <a href='/'>redirected</a>.</body></html>"

    conn
    |> put_resp_cookie(
      Keyword.get(@config_options, :key, @default_key),
      %{ref_code: ref_code},
      options()
    )
    |> put_resp_header("location", "/")
    |> put_resp_content_type("text/html")
    |> send_resp(302, body)
    |> halt()
  end

  def call(conn, _), do: conn

  defp options do
    opts =
      @defaults_opts
      |> Keyword.merge(@config_options)
      |> Enum.reject(&is_nil(elem(&1, 1)))

    @defaults_opts |> Enum.map(fn {k, _} -> {k, Keyword.get(opts, k)} end)
  end
end
