defmodule WedidWeb.Plugs.SetLocale do
  @moduledoc """
  A plug to set the application locale based on various sources.

  The locale is determined in the following order of priority:
  1. URL parameter (?locale=de)
  2. Session value
  3. Cookie value
  4. Accept-Language header
  5. Default locale
  """

  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    locale =
      get_locale_from_params(conn) ||
        get_locale_from_session(conn) ||
        get_locale_from_cookie(conn) ||
        get_locale_from_header(conn) ||
        get_locale_from_accept_language(conn) ||
        get_default_locale()

    if locale in Gettext.known_locales(WedidWeb.Gettext) do
      Gettext.put_locale(WedidWeb.Gettext, locale)

      conn
      |> put_session(:locale, locale)
      |> put_resp_cookie("locale", locale, max_age: 365 * 24 * 60 * 60)
    else
      conn
    end
  end

  defp get_locale_from_params(conn) do
    case conn.params do
      %Plug.Conn.Unfetched{} -> nil
      params when is_map(params) -> params["locale"]
      _ -> nil
    end
  end

  defp get_locale_from_session(conn) do
    get_session(conn, :locale)
  end

  defp get_locale_from_cookie(conn) do
    case conn.req_cookies do
      %Plug.Conn.Unfetched{} -> nil
      cookies when is_map(cookies) -> cookies["locale"]
      _ -> nil
    end
  end

  defp get_locale_from_header(conn) do
    case get_req_header(conn, "x-locale") do
      [value | _] -> value
      _ -> nil
    end
  end

  defp get_locale_from_accept_language(conn) do
    case get_req_header(conn, "accept-language") do
      [value | _] ->
        value
        |> String.split(",")
        |> List.first()
        |> String.split(";")
        |> List.first()
        |> String.trim()
        # Take first 2 chars (e.g., "de" from "de-DE")
        |> String.slice(0, 2)

      _ ->
        nil
    end
  end

  defp get_default_locale do
    # I was unable to read the default locale from WedidWeb.Gettext 
    # It should probably be moved to config and read from there
    "de"
  end
end
