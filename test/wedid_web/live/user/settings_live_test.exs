defmodule WedidWeb.User.SettingsLiveTest do
  use WedidWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "User Settings LiveView" do
    setup :register_and_log_in_user

    test "renders profile form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      assert has_element?(view, "h2", "Profile Information")
      assert has_element?(view, "form")
      assert has_element?(view, "input[name='form[name]']")
    end

    test "updates user name when form is submitted", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings")

      name = "Updated Test Name"

      view
      |> form("form", %{"form[name]" => name})
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
end
