defmodule Wedid.Diaries.DiariesTest do
  use Wedid.DataCase

  # Added this line
  alias Wedid.Diaries.Entry
  import AccountsGenerator, only: [user: 0]
  import DiariesGenerator, only: [entry: 1, tag: 1]
  import Ash.Generator, only: [generate: 1, generate_many: 2]

  require Ash.Query

  @valid_content "This is a test entry content"

  describe "create_entry" do
    test "creates an entry for a couple" do
      user = generate(user())

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
      user = generate(user())
      generate(entry(actor: user))

      entries = Diaries.list_entries!(actor: user)

      assert length(entries) == 1
      [first_entry] = entries

      # user is loaded
      assert first_entry.user.email == user.email
    end

    test "list_entries contains the display_name of the users" do
      user = generate(user())
      generate(entry(actor: user))

      user = Accounts.update_user_profile!(user, "james joice", actor: user)

      entries = Diaries.list_entries!(actor: user)

      assert length(entries) == 1
      [first_entry] = entries

      # user is loaded
      assert first_entry.user.display_name == "james joice"
    end

    test "list_entries with a query" do
      user = generate(user())
      generate(entry(actor: user))
      partner = Accounts.invite_user!(Faker.Internet.email(), user.couple_id, actor: user)
      generate(entry(actor: partner))

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
    @tag :skip
    test "cannot delete a tag if it is assigned to an entry, but can if unassigned" do
      # Changed to use existing user/0 generator
      user = generate(user())
      entry = generate(entry(actor: user))
      tag = generate(tag(actor: user))

      {:ok, entry} = Diaries.update_entry(entry, %{tags: [tag.id]}, actor: user)

      assert length(entry.tags) == 1

      # 2. Attempt to delete the linked tag - should fail
      case Diaries.destroy_tag(tag, actor: user) do
        {:error, changeset} ->
          # Check for the specific validation error message
          # The error structure might be nested, so let's be a bit flexible.
          found_error =
            Enum.any?(changeset.errors, fn error ->
              # Ash.Changeset.validate_associated_not_exists adds error to :base or relationship name
              # Sometimes it might be a generic validation error with a more specific internal detail
              (error.field == :base &&
                 error.message == "Cannot delete a tag that is currently assigned to entries.") ||
                (error.field == :entries &&
                   error.message == "Cannot delete a tag that is currently assigned to entries.") ||
                (error.validation == :validate_associated_not_exists &&
                   error.message =~ "Cannot delete a tag")
            end)

          assert found_error,
                 "Expected validation error for deleting a linked tag, got: #{inspect(changeset.errors)}"

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
      user = generate(user())
      tags = generate_many(tag(actor: user), 2)

      %{user: user, tags: tags}
    end

    test "creating an entry with tags", %{user: user, tags: tags} do
      entry_attrs = %{
        created_at: DateTime.utc_now(),
        tags: for(tag <- tags, do: tag.id)
      }

      entry = Diaries.create_entry!("Entry with tags", entry_attrs, actor: user)

      assert length(entry.tags) == 2

      tag_ids_on_entry = Enum.map(entry.tags, & &1.id)
      assert Enum.all?(tags, fn tag -> tag.id in tag_ids_on_entry end)
    end

    test "updating an entry to add tags", %{user: user, tags: [tag | _]} do
      # Create an entry without tags first
      entry = generate(entry(actor: user))

      entry = Ash.load!(entry, [:tags], actor: user)
      assert length(entry.tags) == 0

      # Update to add tags
      {:ok, entry} = Diaries.update_entry(entry, %{tags: [tag.id]}, actor: user)
      entry = Ash.load!(entry, [:tags], actor: user)

      assert length(entry.tags) == 1
      assert hd(entry.tags).id == tag.id
    end

    test "updating an entry to change tags", %{user: user, tags: [tag1, tag2]} do
      tag = generate(tag(actor: user))

      entry =
        Diaries.create_entry!("Entry to change tags", %{tags: [tag1.id, tag2.id]}, actor: user)

      entry = Ash.load!(entry, [:tags], actor: user)

      assert length(entry.tags) == 2

      # Update to have tag2 and tag
      update_attrs = %{tags: [tag2.id, tag.id]}
      {:ok, entry} = Diaries.update_entry(entry, update_attrs, actor: user)

      entry = Ash.load!(entry, [:tags], actor: user)

      assert length(entry.tags) == 2
      tag_ids_on_entry = Enum.map(entry.tags, & &1.id)
      assert tag2.id in tag_ids_on_entry
      assert tag.id in tag_ids_on_entry
      refute tag1.id in tag_ids_on_entry
    end

    test "updating an entry to remove all tags", %{user: user, tags: [tag | _]} do
      entry =
        Diaries.create_entry!("Entry to remove tags from", %{tags: [tag.id]}, actor: user)

      entry = Ash.load!(entry, [:tags], actor: user)
      assert length(entry.tags) == 1

      # Update to remove all tags
      # Send empty list
      entry = Diaries.update_entry!(entry, %{tags: []}, actor: user)
      entry = Ash.load!(entry, [:tags], actor: user)
      assert length(entry.tags) == 0
    end
  end
end
