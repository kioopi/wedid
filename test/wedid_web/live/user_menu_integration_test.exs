defmodule WedidWeb.UserMenuIntegrationTest do
  use WedidWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "User menu integration" do
    setup :register_and_log_in_user

    test "user menu appears in navbar with correct avatar", %{conn: conn, user: user} do
      {:ok, view, html} = live(conn, ~p"/settings")

      # Check that user menu is rendered
      assert has_element?(view, ".dropdown.dropdown-end")
      assert has_element?(view, ".btn.btn-ghost.btn-circle.avatar")

      # Check gravatar image is present
      gravatar_url = Exgravatar.gravatar_url(to_string(user.email), s: 40, d: "blank")
      assert has_element?(view, "img[src='#{gravatar_url}']")

      # Check fallback text for initial is present (hidden by default)
      expected_initial =
        Ash.load!(user, :display_name).display_name
        |> to_string()
        |> String.first()
        |> String.upcase()

      assert html =~ expected_initial
    end

    test "user menu dropdown shows correct user information", %{conn: conn, user: user} do
      {:ok, _view, html} = live(conn, ~p"/settings")

      # Check menu items are present in rendered HTML
      assert html =~ to_string(user.email)
      assert html =~ "Settings"
      assert html =~ "Sign out"
    end

    test "sign out link works correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      # Check that sign out link exists
      assert has_element?(view, "a[href='/sign-out']")
    end
  end

  describe "User menu with different user scenarios" do
    test "user with custom name shows correct initial", context do
      # Create user with specific name
      user =
        AccountsGenerator.generate(AccountsGenerator.user())

      user = Wedid.Accounts.update_user_profile!(user, "Alice", authorize?: false)
      %{conn: conn} = log_in_user(context, user)

      {:ok, view, _html} = live(conn, ~p"/settings")

      # Should show "A" for Alice
      assert has_element?(view, "span.user-initial", "A")
    end

    test "user without name shows email-based initial", context do
      # Create user without name (name will be nil)
      user =
        AccountsGenerator.generate(AccountsGenerator.user(email: "xaver@example.com"))

      %{conn: conn} = log_in_user(context, user)

      {:ok, view, _html} = live(conn, ~p"/settings")

      # Should show first letter of email part before @
      assert has_element?(view, "span.user-initial", "X")
    end

    test "user menu works with gravatar-enabled email", context do
      # Test with a known email that has a gravatar (using a test email)
      # Note: This would need to be an actual email with a gravatar for real testing
      user =
        AccountsGenerator.generate(AccountsGenerator.user(email: "xaver@example.com"))

      %{conn: conn} = log_in_user(context, user)

      {:ok, view, _html} = live(conn, ~p"/settings")

      # Check that gravatar URL is generated correctly
      expected_gravatar = Exgravatar.gravatar_url("xaver@example.com", s: 40, d: "blank")
      assert has_element?(view, "img[src='#{expected_gravatar}']")
    end
  end

  describe "User menu accessibility and styling" do
    setup :register_and_log_in_user

    test "has proper ARIA attributes and accessibility", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      # Check button has role and tabindex
      assert has_element?(view, "[role='button'][tabindex='0']")

      # Check image has alt text
      assert has_element?(view, "img[alt='Avatar']")
    end
  end
end

