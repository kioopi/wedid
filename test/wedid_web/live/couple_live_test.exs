defmodule WedidWeb.CoupleLiveTest do
  use WedidWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Wedid.Accounts # Added for Accounts.get_user!

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
      view |> element("button", "Add Tag") |> Phoenix.LiveViewTest.click() # Reverted to fully qualified call

      # Assert that the modal is now visible by checking for an element within it,
      # for example, the tag name input field.
      assert has_element?(view, "#tag-modal form#tag-form input[name='new_tag[name]']")

      # Fill in and submit the tag form in the modal
      tag_name = "Holiday Memories"
      tag_icon = "hero-photo"
      tag_color = "#34D399" # A sample hex color (greenish)

      view
      |> form("#tag-modal form#tag-form", %{
        "new_tag[name]" => tag_name,
        "new_tag[icon]" => tag_icon,
        "new_tag[color]" => tag_color
      })
      |> render_submit()

      # Assert success flash message
      assert render(view) =~ "Tag '#{tag_name}' created successfully!"

      # Assert the new tag is displayed on the page
      assert has_element?(view, "span[style*='color: #{tag_color}']", tag_name)
      # Check for an icon with the specified name and color style
      assert has_element?(view, "span > .heroicon[style*='color: #{tag_color}'][name='#{tag_icon}']")

      # Also, verify the tag exists in the database for this user's couple
      reloaded_user = Accounts.get_user!(user.id, actor: user, load: [couple: [:tags]])
      assert Enum.any?(reloaded_user.couple.tags, fn t ->
        t.name == tag_name && t.icon == tag_icon && t.color == tag_color
      end)
    end
  end
end
