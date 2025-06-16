defmodule WedidWeb.CoupleLiveTest do
  use WedidWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "CoupleLive" do
    setup :register_and_log_in_user

    test "displays couple information", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/couple")

      assert has_element?(view, "h2", "Members")
      assert has_element?(view, ".card-title", "Members")
      assert has_element?(view, "button", "Invite Partner")
    end

    test "can invite a partner", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/couple")

      email = Faker.Internet.email()

      view
      |> form("#invite-modal form", %{"form[email]" => email})
      |> render_submit()

      assert has_element?(view, "p", "Partner invitation sent successfully!")
      assert has_element?(view, "td", email)
    end

    test "can create a new tag", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/couple")

      # Ensure the Tag Management section is present
      assert has_element?(view, "h2.card-title", "Tag Management")
      assert has_element?(view, "button", "Create Tag")

      # Check that the inline tag creation form is present
      assert has_element?(view, "#new-tag-form input[name='form[name]']")
      assert has_element?(view, "#new-tag-form input[name='form[icon]']")
      assert has_element?(view, "#new-tag-form input[name='form[color]']")

      # Fill in and submit the tag form
      tag_name = "Holiday Memories"
      tag_icon = "🏖️"  # Using emoji instead of heroicon
      tag_color = "#34D399"

      view
      |> form("#new-tag-form", %{
        "form[name]" => tag_name,
        "form[icon]" => tag_icon,
        "form[color]" => tag_color
      })
      |> render_submit()

      # Assert the new tag is displayed on the page
      assert has_element?(view, "span", tag_name)
      assert has_element?(view, "span", tag_icon)

      # Also, verify the tag exists in the database for this user's couple
      user = Ash.load!(user, [couple: [:tags]], actor: user)

      assert Enum.any?(user.couple.tags, fn t ->
               t.name == tag_name && t.icon == tag_icon && t.color == tag_color
             end)
    end
  end
end
