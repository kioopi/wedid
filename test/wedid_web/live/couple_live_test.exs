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

      # Ensure the Tags section and Add Tag button are present
      assert has_element?(view, "h2.card-title", "Tags")
      assert has_element?(view, "button", "Add Tag")

      # Click "Add Tag" button to open modal
      # LiveViewTests do not support clicking dispatch
      # view |> element("button", "Add Tag") |> render_click()

      # Assert that the modal is now visible by checking for an element within it,
      # for example, the tag name input field.
      assert has_element?(view, "#tag-modal input[name='form[name]']")

      # Fill in and submit the tag form in the modal
      tag_name = "Holiday Memories"
      tag_icon = "hero-photo"
      # A sample hex color (greenish)
      tag_color = "#34D399"

      view
      |> form("#tag-modal form", %{
        "form[name]" => tag_name,
        "form[icon]" => tag_icon,
        "form[color]" => tag_color
      })
      |> render_submit()

      # Assert success flash message
      # assert render(view) =~ "Tag '#{tag_name}' created successfully!"

      # Assert the new tag is displayed on the page
      assert has_element?(view, "span[style*='color: #{tag_color}']", tag_name)
      # Check for an icon with the specified name and color style
      assert has_element?(view, "span.#{tag_icon}")

      # Also, verify the tag exists in the database for this user's couple
      user = Ash.load!(user, [couple: [:tags]], actor: user)

      assert Enum.any?(user.couple.tags, fn t ->
               t.name == tag_name && t.icon == tag_icon && t.color == tag_color
             end)
    end
  end
end
