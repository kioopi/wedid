defmodule WedidWeb.CoupleLiveTest do
  use WedidWeb.ConnCase

  import Phoenix.LiveViewTest
  alias Wedid.Account.Generator

  describe "CoupleLive" do
    setup :register_and_log_in_user

    test "displays couple information", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/couple")

      assert has_element?(view, "h2", "Members")
      assert has_element?(view, ".card-title", "Members")
      assert has_element?(view, "button", "Invite Partner")
    end

    test "can open and close the invite modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/couple")

      refute has_element?(view, "#invite-modal")

      view |> element("button", "Invite Partner") |> render_click()
      assert has_element?(view, "#invite-modal")

      view |> element("#invite-modal button", "Cancel") |> render_click()
      refute has_element?(view, "#invite-modal")
    end

    test "can invite a partner", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/couple")

      email = Faker.Internet.email()

      view |> element("button", "Invite Partner") |> render_click()

      view
      |> form("#invite-modal form", %{"form[email]" => email})
      |> render_submit()

      assert has_element?(view, "p", "Partner invitation sent successfully!")
      assert has_element?(view, "td", email)
    end
  end
end
