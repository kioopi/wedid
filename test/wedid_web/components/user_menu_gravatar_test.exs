defmodule WedidWeb.UserMenuGravatarFunctionalTest do
  use WedidWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "User menu Gravatar functionality" do
    setup :register_and_log_in_user

    test "generates correct gravatar URL for user email", %{user: user} do
      expected_url = Exgravatar.gravatar_url(to_string(user.email), s: 40, d: "blank")

      # Verify URL structure
      assert String.starts_with?(expected_url, "https://secure.gravatar.com/avatar/")
      assert String.contains?(expected_url, "s=40")
      assert String.contains?(expected_url, "d=blank")
    end

    test "gravatar URL is consistent for same email", %{user: user} do
      url1 = Exgravatar.gravatar_url(to_string(user.email), s: 40, d: "blank")
      url2 = Exgravatar.gravatar_url(to_string(user.email), s: 40, d: "blank")

      assert url1 == url2
    end

    test "different emails generate different gravatar URLs" do
      email1 = "user1@example.com"
      email2 = "user2@example.com"

      url1 = Exgravatar.gravatar_url(email1, s: 40, d: "blank")
      url2 = Exgravatar.gravatar_url(email2, s: 40, d: "blank")

      assert url1 != url2
    end

    test "user menu renders with gravatar and fallback in settings page", %{
      conn: conn,
      user: user
    } do
      {:ok, view, html} = live(conn, ~p"/settings")

      # Check that user menu is rendered
      assert has_element?(view, ".dropdown.dropdown-end")
      assert has_element?(view, ".btn.btn-ghost.btn-circle.avatar")

      # Check gravatar image is present in HTML (URL may be HTML-encoded)
      gravatar_url = Exgravatar.gravatar_url(to_string(user.email), s: 40, d: "blank")
      # URL will be HTML-encoded in the output, so check for the encoded version
      encoded_gravatar_url = String.replace(gravatar_url, "&", "&amp;")
      assert html =~ encoded_gravatar_url

      # Check fallback mechanism is present
      assert has_element?(view, "img[onerror]")

      # Check that fallback letter is in the HTML (even though it's hidden by default)
      # The first letter should be "U" for "user0" (from generated email)
      # Look for the span with the initial letter
      assert has_element?(view, "span.user-initial", "U")
    end

    test "user menu dropdown contains correct menu items", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      html = element(view, ".dropdown-end") |> render()

      # Check menu items are present in HTML
      assert html =~ to_string(user.email)
      assert html =~ "Settings"
      assert html =~ "Sign out"
      assert html =~ "/settings"
      assert html =~ "/sign-out"
    end

    test "email normalization for gravatar lookup" do
      email = "TEST@Example.Com"
      email_lower = String.downcase(email)

      url_mixed = Exgravatar.gravatar_url(email, s: 40, d: "blank")
      url_lower = Exgravatar.gravatar_url(email_lower, s: 40, d: "blank")

      # Gravatar should normalize to lowercase, so URLs should be the same
      assert url_mixed == url_lower
    end

    test "user menu accessibility attributes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      # Check accessibility attributes
      assert has_element?(view, "[role='button'][tabindex='0']")
      assert has_element?(view, "img[alt='Avatar']")
    end
  end

  describe "Gravatar URL generation edge cases" do
    test "handles empty email gracefully" do
      # Should not crash with empty email
      url = Exgravatar.gravatar_url("", s: 40, d: "blank")
      assert String.starts_with?(url, "https://secure.gravatar.com/avatar/")
    end

    test "handles very long email" do
      long_email = String.duplicate("a", 100) <> "@example.com"
      url = Exgravatar.gravatar_url(long_email, s: 40, d: "blank")
      assert String.starts_with?(url, "https://secure.gravatar.com/avatar/")
    end

    test "handles special characters in email" do
      special_email = "test+tag@example.com"
      url = Exgravatar.gravatar_url(special_email, s: 40, d: "blank")
      assert String.starts_with?(url, "https://secure.gravatar.com/avatar/")
    end
  end
end

