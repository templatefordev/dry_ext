defmodule DryExt.Plugs.SetReferralCookie do
  @moduledoc """
  The plug set referral cookie if not exists and redirect
  to request_path location if query params contains `?ref=[ref_code]`.

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
        max_age: 60 * 60 * 24 * 365,
        domain: "example.com"

    Options:

      * `key` - optional(default: "_dry_ext_ref_key"), name of cookie.
        And then `Plug.Conn.fetch_cookies(conn, signed: ~w(_dry_ext_ref_key))`.
      * `max_age` - optional(default: 365 days),the cookie max-age, in seconds.
      * `domain` - optional, the domain the cookie applies to.
  """
  @behaviour Plug

  alias Plug.Conn

  import Plug.Conn,
    only: [
      assign: 3,
      fetch_cookies: 2,
      put_resp_cookie: 4,
      put_resp_header: 3,
      put_resp_content_type: 2,
      send_resp: 3,
      halt: 1
    ]

  @default_max_age 60 * 60 * 24 * 365
  @default_key "_dry_ext_ref_key"

  @defaults_opts [sign: true, max_age: @default_max_age, domain: nil]

  defmacrop is_cookie_key(cookies) do
    quote do: is_map_key(unquote(cookies), unquote(key()))
  end

  defp config_opts do
    Application.get_env(:dry_ext, :referral_cookie, [])
  end

  defp key do
    Keyword.get(config_opts(), :key, @default_key)
  end

  @spec init(any) :: keyword
  def init(_opts) do
    @defaults_opts
    |> Keyword.merge(config_opts())
    |> Enum.reject(&is_nil(elem(&1, 1)))
    |> Keyword.take(Keyword.keys(@defaults_opts))
  end

  def call(%Conn{params: %{"ref" => _}, request_path: path} = conn, _opts)
      when is_cookie_key(conn.cookies) do
    conn |> redirect(path)
  end

  def call(%Conn{params: %{"ref" => ref_code}, request_path: path} = conn, opts) do
    conn
    |> put_resp_cookie(key(), %{ref_code: ref_code}, opts)
    |> redirect(path)
  end

  def call(conn, _), do: conn

  defp redirect(conn, path) do
    body = "<html><body>You are being <a href='/'>redirected</a>.</body></html>"

    conn
    |> put_resp_header("location", path)
    |> put_resp_content_type("text/html")
    |> send_resp(302, body)
    |> halt()
  end

  @doc """
  A plug to assign referral_code if exists referral cookie.

  ## Example:

      import DryExt.Plugs.SetReferralCookie, only: [assign_referral_code: 2]

      plug :assign_referral_code

  then you can use it:

      iex> conn.assigns.referral_code
      "asdf"
  """
  def assign_referral_code(conn, _opts) when is_cookie_key(conn.cookies) do
    ref_code =
      conn
      |> fetch_cookies(signed: [key()])
      |> Map.from_struct()
      |> get_in([:cookies, key(), :ref_code])

    assign(conn, :referral_code, ref_code)
  end

  def assign_referral_code(conn, _), do: conn
end
