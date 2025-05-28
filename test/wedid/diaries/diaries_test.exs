defmodule Wedid.Diaries.DiariesTest do
  use Wedid.DataCase

  alias Wedid.Diaries.Entry # Added this line

  require Ash.Query

  @valid_content "This is a test entry content"

  describe "create_entry" do
    test "creates an entry for a couple" do
      user = generate(AccountsGenerator.user())

      entry =
        Diaries.create_entry!(
          @valid_content,
          %{created_at: DateTime.utc_now()},
          actor: user
        )

      assert entry.content == @valid_content
      assert entry.couple_id == user.couple_id
    end
  end

  describe "list_entries" do
    test "list_entries of a couple" do
      user = generate(AccountsGenerator.user())
      generate(DiariesGenerator.entry(actor: user))

      entries = Diaries.list_entries!(actor: user)

      assert length(entries) == 1
      [first_entry] = entries

      # user is loaded
      assert first_entry.user.email == user.email
    end

    test "list_entries contains the display_name of the users" do
      user = generate(AccountsGenerator.user())
      generate(DiariesGenerator.entry(actor: user))

      user = Accounts.update_user_profile!(user, "james joice", actor: user)

      entries = Diaries.list_entries!(actor: user)

      assert length(entries) == 1
      [first_entry] = entries

      # user is loaded
      assert first_entry.user.display_name == "james joice"
    end

    test "list_entries with a query" do
      user = generate(AccountsGenerator.user())
      generate(DiariesGenerator.entry(actor: user))
      partner = Accounts.invite_user!(Faker.Internet.email(), user.couple_id, actor: user)
      generate(DiariesGenerator.entry(actor: partner))

      entries =
        Diaries.list_entries!(
          actor: user,
          query: Ash.Query.filter(Entry, user_id != ^user.id)
        )

      assert length(entries) == 1

      [first_entry] = entries
      # entry only contains the partner's entry
      assert first_entry.user.email == partner.email

      assert first_entry.user.display_name ==
               to_string(partner.email) |> String.split("@") |> List.first()
    end
  end

  describe "Tag Deletion Protection" do
    test "cannot delete a tag if it is assigned to an entry, but can if unassigned" do
      user = generate(AccountsGenerator.user()) # Changed to use existing user/0 generator
      entry = generate(DiariesGenerator.entry(actor: user))
      tag_attrs = %{name: "Test Tag for Deletion", icon: "hero-trash", color: "red"}

      # Create the tag directly for the user's couple
      # The create action in Tag resource sets couple_id from actor
      {:ok, tag} = Diaries.create_tag(tag_attrs, actor: user) # Changed this line

      # 1. Link the tag to the entry
      # We use :direct_control, so provide the full list of tags for the entry.
      update_attrs_link = %{
        tags: [%{tag_id: tag.id, role: :main}] # Changed id to tag_id
      }
      {:ok, _entry_with_tag} = Diaries.update_entry(entry, update_attrs_link, actor: user)

      # 2. Attempt to delete the linked tag - should fail
      case Diaries.destroy_tag(tag, actor: user) do
        {:error, changeset} ->
          # Check for the specific validation error message
          # The error structure might be nested, so let's be a bit flexible.
          found_error = Enum.any?(changeset.errors, fn error ->
            # Ash.Changeset.validate_associated_not_exists adds error to :base or relationship name
            (error.field == :base && error.message == "Cannot delete a tag that is currently assigned to entries.") ||
            (error.field == :entries && error.message == "Cannot delete a tag that is currently assigned to entries.") ||
            # Sometimes it might be a generic validation error with a more specific internal detail
            (error.validation == :validate_associated_not_exists && error.message =~ "Cannot delete a tag")
          end)
          assert found_error, "Expected validation error for deleting a linked tag, got: #{inspect(changeset.errors)}"
        {:ok, _} ->
          flunk("Should not have allowed deleting a tag that is assigned to an entry")
        other_error ->
          flunk("Unexpected error when trying to delete linked tag: #{inspect(other_error)}")
      end

      # 3. Unlink the tag from the entry
      # Update the entry with an empty list of tags
      update_attrs_unlink = %{tags: []}
      {:ok, _entry_without_tag} = Diaries.update_entry(entry, update_attrs_unlink, actor: user)


      # 4. Attempt to delete the tag again - should succeed
      assert {:ok, _deleted_tag} = Diaries.destroy_tag(tag, actor: user)

      # 5. Verify the tag is actually deleted
      assert {:error, %Ash.Error.Query.NotFound{}} = Diaries.read_tag_by_id(tag.id, actor: user)
    end
  end

  describe "Entry Tagging Logic" do
    setup do
      user = generate(AccountsGenerator.user())
      # Create a couple of tags for this user's couple
      {:ok, tag1_rec} = Diaries.create_tag(%{name: "Tag One", color: "blue"}, actor: user)
      {:ok, tag2_rec} = Diaries.create_tag(%{name: "Tag Two", color: "green"}, actor: user)
      %{user: user, tag1: tag1_rec, tag2: tag2_rec} # Store the records
    end

    test "creating an entry with tags", %{user: user, tag1: tag1, tag2: tag2} do
      entry_attrs = %{
        content: "Entry with tags",
        created_at: DateTime.utc_now(),
        tags_in: [tag1.id, tag2.id] # Using :tags_in as per the Entry action argument
      }

      {:ok, entry} = Diaries.create_entry(entry_attrs, actor: user)

      # Verify entry and tags
      loaded_entry = Diaries.read_entry_by_id!(entry.id, actor: user, load: [:tags])
      assert length(loaded_entry.tags) == 2
      tag_ids_on_entry = Enum.map(loaded_entry.tags, & &1.id)
      assert tag1.id in tag_ids_on_entry
      assert tag2.id in tag_ids_on_entry
    end

    test "updating an entry to add tags", %{user: user, tag1: tag1} do
      # Create an entry without tags first
      entry_initial_attrs = %{content: "Initial entry", created_at: DateTime.utc_now()}
      {:ok, entry} = Diaries.create_entry(entry_initial_attrs, actor: user)
      
      # Use Ash.load! directly as read_entry_by_id! might not exist or implies more than just loading
      loaded_initial_entry = Ash.load!(entry, [:tags], actor: user)
      assert length(loaded_initial_entry.tags) == 0

      # Update to add tags
      update_attrs = %{tags_in: [tag1.id]}
      {:ok, updated_entry} = Diaries.update_entry(entry, update_attrs, actor: user)

      loaded_entry = Diaries.read_entry_by_id!(updated_entry.id, actor: user, load: [:tags])
      assert length(loaded_entry.tags) == 1
      assert hd(loaded_entry.tags).id == tag1.id
    end

    test "updating an entry to change tags", %{user: user, tag1: tag1, tag2: tag2} do
      # Create another tag
      {:ok, tag3} = Diaries.create_tag(%{name: "Tag Three", color: "purple"}, actor: user)

      # Create an entry with tag1 and tag2
      entry_initial_attrs = %{
        content: "Entry to change tags",
        created_at: DateTime.utc_now(),
        tags_in: [tag1.id, tag2.id]
      }
      {:ok, entry} = Diaries.create_entry(entry_initial_attrs, actor: user)
      loaded_entry_before_update = Diaries.read_entry_by_id!(entry.id, actor: user, load: [:tags])
      assert length(loaded_entry_before_update.tags) == 2

      # Update to have tag2 and tag3
      update_attrs = %{tags_in: [tag2.id, tag3.id]}
      {:ok, updated_entry} = Diaries.update_entry(entry, update_attrs, actor: user)

      loaded_entry_after_update = Diaries.read_entry_by_id!(updated_entry.id, actor: user, load: [:tags])
      assert length(loaded_entry_after_update.tags) == 2
      tag_ids_on_entry = Enum.map(loaded_entry_after_update.tags, & &1.id)
      assert tag2.id in tag_ids_on_entry
      assert tag3.id in tag_ids_on_entry
      refute tag1.id in tag_ids_on_entry
    end

    test "updating an entry to remove all tags", %{user: user, tag1: tag1} do
      # Create an entry with tag1
      entry_initial_attrs = %{
        content: "Entry to remove tags from",
        created_at: DateTime.utc_now(),
        tags_in: [tag1.id]
      }
      {:ok, entry} = Diaries.create_entry(entry_initial_attrs, actor: user)
      loaded_entry_before_update = Diaries.read_entry_by_id!(entry.id, actor: user, load: [:tags])
      assert length(loaded_entry_before_update.tags) == 1

      # Update to remove all tags
      update_attrs = %{tags_in: []} # Send empty list
      {:ok, updated_entry} = Diaries.update_entry(entry, update_attrs, actor: user)

      loaded_entry_after_update = Diaries.read_entry_by_id!(updated_entry.id, actor: user, load: [:tags])
      assert length(loaded_entry_after_update.tags) == 0
    end
  end
end
