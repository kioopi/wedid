defmodule WedidWeb.User.SettingsLiveTest do
  use WedidWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "User Settings LiveView" do
    setup :register_and_log_in_user

    test "renders profile form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      assert has_element?(view, "h2", "Profile information")
      assert has_element?(view, "input[name='form[name]']")
    end

    test "updates user name when form is submitted", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      name = "Updated Test Name"

      view
      |> form("form.profile-form", %{"form[name]" => name})
      |> render_submit()

      # Check that flash message appears
      assert render(view) =~ "Profile updated successfully"

      # Check that user was updated in the database
      updated_user =
        Wedid.Accounts.User
        |> Ash.get!(conn.assigns.current_user.id, authorize?: false)

      assert updated_user.name == "Updated Test Name"
    end
  end

  # the tests for this might need to be rewritten in PhoenixTest
  describe "Theme Switcher" do
    setup :register_and_log_in_user

    @tag :skip
    test "renders theme controller and checks initial theme", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      assert has_element?(view, "#theme-switcher")
      assert has_element?(view, "input[data-set-theme='light'][aria-label='Default']")
      assert has_element?(view, "input[data-set-theme='dark'][aria-label='Dark']")
      assert has_element?(view, "input[data-set-theme='cupcake'][aria-label='Cupcake']")

      assert view |> element(~s|html[data-theme="light"]|) |> has_element?()

      # Re-fetch the view to ensure JavaScript has run
      {:ok, view, _html} = live(conn, ~p"/settings")

      default_radio_checked =
        has_element?(view, "input[data-set-theme='light'][aria-label='Default']:checked")

      assert default_radio_checked
    end

    # Skipping this test. LiveViewTest cant handle JavaScript interactions directly.
    @tag :skip
    test "selecting a theme updates data-theme", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      view
      |> element("input[data-set-theme='cupcake']")
      |> render_click()

      # Wait for DOM changes if necessary, though click should be synchronous for this
      Process.sleep(100)

      assert view |> element(~s|html[data-theme="cupcake"]|) |> has_element?()

      {:ok, view, _html} = live(conn, ~p"/settings")

      assert view |> element(~s|html[data-theme="cupcake"]|) |> has_element?()
    end
  end
end
