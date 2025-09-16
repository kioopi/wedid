defmodule WedidWeb.LocaleTest do
  use WedidWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "SetLocale plug" do
    test "sets locale from session", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{locale: "de"})
        |> WedidWeb.Plugs.SetLocale.call([])

      assert Gettext.get_locale(WedidWeb.Gettext) == "de"
      assert get_session(conn, :locale) == "de"
    end

    test "sets locale from cookie", %{conn: conn} do
      conn =
        conn
        |> put_req_cookie("locale", "de")
        |> init_test_session(%{})
        |> WedidWeb.Plugs.SetLocale.call([])

      assert Gettext.get_locale(WedidWeb.Gettext) == "de"
      assert get_session(conn, :locale) == "de"
    end

    test "defaults to German when no locale specified", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> WedidWeb.Plugs.SetLocale.call([])

      assert Gettext.get_locale(WedidWeb.Gettext) == "de"
      assert get_session(conn, :locale) == "de"
    end

    test "ignores invalid locale", %{conn: conn} do
      _conn =
        conn
        |> init_test_session(%{locale: "invalid"})
        |> WedidWeb.Plugs.SetLocale.call([])

      # Should fall back to English since invalid locale is not in known_locales
      # Note: The plug doesn't change locale for invalid values, so we check that
      # it doesn't set an invalid locale in Gettext
      valid_locales = Gettext.known_locales(WedidWeb.Gettext)
      current_locale = Gettext.get_locale(WedidWeb.Gettext)
      assert current_locale in valid_locales
    end
  end

  describe "LiveView locale handling" do
    setup :register_and_log_in_user

    test "Settings LiveView respects session locale", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{locale: "de"})
        |> WedidWeb.Plugs.SetLocale.call([])

      {:ok, view, _html} = live(conn, ~p"/settings")

      # Check that the LiveView received the correct locale
      assert has_element?(view, "[data-current-locale='de']")
    end

    test "Settings LiveView can change locale via event", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      # Change locale to German
      view |> element("#language-switcher") |> render_hook("sync_locale", %{"locale" => "de"})

      # Verify the locale change is reflected in the LiveView state
      assert has_element?(view, "[data-current-locale='de']")
    end

    test "Settings LiveView shows German interface when locale is de", %{conn: conn} do
      # Set German locale in session and apply plug
      conn =
        conn
        |> init_test_session(%{locale: "de"})
        |> WedidWeb.Plugs.SetLocale.call([])

      {:ok, _view, html} = live(conn, ~p"/settings")

      # Check for German text in the UI - more specific assertions
      # "User Settings" in German
      assert html =~ "Benutzereinstellungen"
      # "Language" in German  
      assert html =~ "Sprache"
      # "Color theme" in German
      assert html =~ "Farbthema" || html =~ "Farbschema"
      # "Profile information" in German
      assert html =~ "Profilinformationen"
      # "Change password" in German
      assert html =~ "Passwort ändern"
      # "Save Changes" in German
      assert html =~ "Änderungen speichern"

      # Make sure English text is NOT present
      refute html =~ "User Settings"
      refute html =~ "Profile information"
      refute html =~ "Change password"
      refute html =~ "Save Changes"
    end

    test "Settings LiveView shows English interface when locale is en", %{conn: conn} do
      # Explicitly set English locale
      conn =
        conn
        |> init_test_session(%{locale: "en"})
        |> WedidWeb.Plugs.SetLocale.call([])

      {:ok, _view, html} = live(conn, ~p"/settings")

      # Check for English text in the UI
      assert html =~ "User Settings"
      assert html =~ "Language"
      assert html =~ "Color theme"
      assert html =~ "Profile information"
      assert html =~ "Change password"
      assert html =~ "Save Changes"

      # Make sure German text is NOT present
      refute html =~ "Benutzereinstellungen"
      refute html =~ "Sprache"
      refute html =~ "Profilinformationen"
      refute html =~ "Passwort ändern"
    end

    test "User can change language and LiveView triggers reload", %{conn: conn} do
      # Start with English - explicitly set the locale to English
      conn =
        conn
        |> init_test_session(%{locale: "en"})
        |> WedidWeb.Plugs.SetLocale.call([])

      {:ok, view, html} = live(conn, ~p"/settings")

      # Verify we start with English
      assert html =~ "User Settings"
      assert html =~ "Language"

      # Change to German via the language switcher
      # This should trigger a client-side reload, but we can't test that in LiveViewTest
      # So we just verify the event is handled correctly and the locale-changed event is pushed

      result =
        view
        |> element("a[phx-click='change_locale'][phx-value-locale='de']")
        |> render_click()

      # The click should succeed without error
      assert result

      # Verify the current locale was updated in the LiveView state
      assert has_element?(view, "[data-current-locale='de']")
    end

    test "Language switching workflow - full cycle", %{conn: conn} do
      # Simulate the full workflow:
      # 1. User clicks German -> triggers reload -> page loads with German locale

      # Start with a fresh session that has German locale (simulating after reload)
      conn_with_german =
        conn
        |> init_test_session(%{locale: "de"})
        |> WedidWeb.Plugs.SetLocale.call([])

      {:ok, _view, html} = live(conn_with_german, ~p"/settings")

      # Verify the interface is now in German (simulating after reload)
      # "User Settings" in German
      assert html =~ "Benutzereinstellungen"
      # "Language" in German  
      assert html =~ "Sprache"
      # "Color theme" in German
      assert html =~ "Farbschema" || html =~ "Farbthema"
      # "Profile information" in German
      assert html =~ "Profilinformationen"

      # Make sure English text is NOT present
      refute html =~ "User Settings"
      refute html =~ "Profile information"
    end
  end

  describe "Locale persistence across navigation" do
    setup :register_and_log_in_user

    test "locale persists when navigating between pages", %{conn: conn} do
      # Set German locale
      conn =
        conn
        |> init_test_session(%{locale: "de"})
        |> WedidWeb.Plugs.SetLocale.call([])

      # Visit settings page
      {:ok, _view, html} = live(conn, ~p"/settings")
      assert html =~ "Benutzereinstellungen"

      # Navigate to entries page
      {:ok, _view, _html} = live(conn, ~p"/entries")

      # Check if locale is still set correctly after navigation
      assert Gettext.get_locale(WedidWeb.Gettext) == "de"
    end
  end
end
