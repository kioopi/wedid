defmodule Wedid.Diaries.EntryTagTest do
  use Wedid.DataCase

  alias Wedid.Diaries
  alias Wedid.Diaries.EntryTag
  alias Wedid.Accounts

  import AccountsGenerator, only: [user: 0]
  import DiariesGenerator, only: [entry: 1, tag: 1]
  import Ash.Generator, only: [generate: 1]

  require Ash.Query

  describe "EntryTag creation" do
    setup do
      user = generate(user())
      entry = generate(entry(actor: user))
      tag = generate(tag(actor: user))

      %{user: user, entry: entry, tag: tag}
    end

    test "user can create an EntryTag linking their entry with their couple's tag", %{
      user: user,
      entry: entry,
      tag: tag
    } do
      entry_tag_attrs = %{
        entry_id: entry.id,
        tag_id: tag.id,
        role: :main
      }

      {:ok, entry_tag} =
        EntryTag
        |> Ash.Changeset.for_create(:create, entry_tag_attrs, actor: user)
        |> Ash.create()

      assert entry_tag.entry_id == entry.id
      assert entry_tag.tag_id == tag.id
      assert entry_tag.role == :main
    end

    test "user can create an EntryTag without a role", %{user: user, entry: entry, tag: tag} do
      entry_tag_attrs = %{
        entry_id: entry.id,
        tag_id: tag.id
      }

      {:ok, entry_tag} =
        EntryTag
        |> Ash.Changeset.for_create(:create, entry_tag_attrs, actor: user)
        |> Ash.create()

      assert entry_tag.entry_id == entry.id
      assert entry_tag.tag_id == tag.id
      assert is_nil(entry_tag.role)
    end

    test "cannot create EntryTag with a tag that doesn't belong to the couple", %{
      user: user,
      entry: entry
    } do
      # Create another user with a different couple
      other_user = generate(user())
      other_couples_tag = generate(tag(actor: other_user))

      entry_tag_attrs = %{
        entry_id: entry.id,
        tag_id: other_couples_tag.id,
        role: :main
      }

      assert {:error, %Ash.Error.Forbidden{}} =
               EntryTag
               |> Ash.Changeset.for_create(:create, entry_tag_attrs, actor: user)
               |> Ash.create()
    end

    test "cannot create EntryTag with an entry that doesn't belong to the couple", %{
      user: user,
      tag: tag
    } do
      # Create another user with a different couple
      other_user = generate(user())
      other_couples_entry = generate(entry(actor: other_user))

      entry_tag_attrs = %{
        entry_id: other_couples_entry.id,
        tag_id: tag.id,
        role: :main
      }

      assert {:error, %Ash.Error.Forbidden{}} =
               EntryTag
               |> Ash.Changeset.for_create(:create, entry_tag_attrs, actor: user)
               |> Ash.create()
    end
  end

  describe "EntryTag unique main role constraint" do
    setup do
      user = generate(user())
      entry = generate(entry(actor: user))
      tag1 = generate(tag(actor: user))
      tag2 = generate(tag(actor: user))

      %{user: user, entry: entry, tag1: tag1, tag2: tag2}
    end

    test "can only have one tag with role :main per entry", %{
      user: user,
      entry: entry,
      tag1: tag1,
      tag2: tag2
    } do
      # Create first EntryTag with role :main
      {:ok, _entry_tag1} =
        EntryTag
        |> Ash.Changeset.for_create(
          :create,
          %{entry_id: entry.id, tag_id: tag1.id, role: :main},
          actor: user
        )
        |> Ash.create()

      # Attempt to create second EntryTag with role :main for the same entry
      assert {:error, changeset} =
               EntryTag
               |> Ash.Changeset.for_create(
                 :create,
                 %{entry_id: entry.id, tag_id: tag2.id, role: :main},
                 actor: user
               )
               |> Ash.create()

      # Check for identity constraint violation
      found_identity_error =
        Enum.any?(changeset.errors, fn error ->
          error.message =~ ~r/unique_main_tag_for_entry/i ||
            error.message =~ ~r/violates unique constraint/i ||
            error.message =~ ~r/already exists/i ||
            error.message =~ ~r/has already been taken/i
        end)

      assert found_identity_error,
             "Expected unique constraint violation, got: #{inspect(changeset.errors)}"
    end

    test "can have multiple tags with different roles or nil role per entry", %{
      user: user,
      entry: entry,
      tag1: tag1,
      tag2: tag2
    } do
      # Create first EntryTag with role :main
      {:ok, entry_tag1} =
        EntryTag
        |> Ash.Changeset.for_create(
          :create,
          %{entry_id: entry.id, tag_id: tag1.id, role: :main},
          actor: user
        )
        |> Ash.create()

      # Create second EntryTag with no role (nil)
      {:ok, entry_tag2} =
        EntryTag
        |> Ash.Changeset.for_create(
          :create,
          %{entry_id: entry.id, tag_id: tag2.id},
          actor: user
        )
        |> Ash.create()

      assert entry_tag1.role == :main
      assert is_nil(entry_tag2.role)

      # Verify both EntryTags exist for the same entry
      entry_tags = Ash.Query.filter(EntryTag, entry_id == ^entry.id) |> Ash.read!(actor: user)

      assert length(entry_tags) == 2
    end

    test "can have tags with role :main for different entries", %{
      user: user,
      tag1: tag1,
      tag2: tag2
    } do
      entry1 = generate(entry(actor: user))
      entry2 = generate(entry(actor: user))

      # Create EntryTag with role :main for first entry
      {:ok, entry_tag1} =
        EntryTag
        |> Ash.Changeset.for_create(
          :create,
          %{entry_id: entry1.id, tag_id: tag1.id, role: :main},
          actor: user
        )
        |> Ash.create()

      # Create EntryTag with role :main for second entry - this should succeed
      {:ok, entry_tag2} =
        EntryTag
        |> Ash.Changeset.for_create(
          :create,
          %{entry_id: entry2.id, tag_id: tag2.id, role: :main},
          actor: user
        )
        |> Ash.create()

      assert entry_tag1.role == :main
      assert entry_tag2.role == :main
      assert entry_tag1.entry_id != entry_tag2.entry_id
    end
  end

  describe "EntryTag authorization" do
    setup do
      user1 = generate(user())
      user2 = generate(user())
      entry = generate(entry(actor: user1))
      tag = generate(tag(actor: user1))

      {:ok, entry_tag} =
        EntryTag
        |> Ash.Changeset.for_create(
          :create,
          %{entry_id: entry.id, tag_id: tag.id, role: :main},
          actor: user1
        )
        |> Ash.create()

      %{user1: user1, user2: user2, entry: entry, tag: tag, entry_tag: entry_tag}
    end

    test "user can read EntryTags for their couple's entries and tags", %{
      user1: user1,
      entry_tag: entry_tag
    } do
      loaded_entry_tag = Ash.get!(EntryTag, entry_tag.id, actor: user1)
      assert loaded_entry_tag.id == entry_tag.id
    end

    test "user cannot read EntryTags for other couples", %{user2: user2, entry_tag: entry_tag} do
      assert {:error, %Ash.Error.Invalid{}} =
               Ash.get(EntryTag, entry_tag.id, actor: user2)
    end

    test "user can update EntryTags for their couple", %{user1: user1, entry_tag: entry_tag} do
      {:ok, updated_entry_tag} =
        entry_tag
        |> Ash.Changeset.for_update(:update, %{role: nil}, actor: user1)
        |> Ash.update()

      assert is_nil(updated_entry_tag.role)
    end

    test "user cannot update EntryTags for other couples", %{user2: user2, entry_tag: entry_tag} do
      assert {:error, %Ash.Error.Forbidden{}} =
               entry_tag
               |> Ash.Changeset.for_update(:update, %{role: nil}, actor: user2)
               |> Ash.update()
    end

    test "user can destroy EntryTags for their couple's entries", %{
      user1: user1,
      entry_tag: entry_tag
    } do
      :ok =
        entry_tag
        |> Ash.Changeset.for_destroy(:destroy)
        |> Ash.destroy(actor: user1)

      assert {:error, %Ash.Error.Invalid{}} =
               Ash.get(EntryTag, entry_tag.id, actor: user1)
    end

    test "user cannot destroy EntryTags for other couples", %{user2: user2, entry_tag: entry_tag} do
      assert {:error, %Ash.Error.Forbidden{}} =
               entry_tag
               |> Ash.Changeset.for_destroy(:destroy)
               |> Ash.destroy(actor: user2)
    end
  end

  describe "EntryTag with partner in couple" do
    test "partner can create EntryTags for entries in the shared couple" do
      user = generate(user())
      partner = Accounts.invite_user!(Faker.Internet.email(), user.couple_id, actor: user)
      
      # Create entry by user, tag by partner
      entry = generate(entry(actor: user))
      tag = generate(tag(actor: partner))

      # Partner should be able to link user's entry with partner's tag
      {:ok, entry_tag} =
        EntryTag
        |> Ash.Changeset.for_create(
          :create,
          %{entry_id: entry.id, tag_id: tag.id, role: :main},
          actor: partner
        )
        |> Ash.create()

      assert entry_tag.entry_id == entry.id
      assert entry_tag.tag_id == tag.id
    end

    test "partner can manage EntryTags in the shared couple" do
      user = generate(user())
      partner = Accounts.invite_user!(Faker.Internet.email(), user.couple_id, actor: user)
      
      entry = generate(entry(actor: user))
      tag = generate(tag(actor: user))

      # User creates EntryTag
      {:ok, entry_tag} =
        EntryTag
        |> Ash.Changeset.for_create(
          :create,
          %{entry_id: entry.id, tag_id: tag.id, role: :main},
          actor: user
        )
        |> Ash.create()

      # Partner should be able to read it
      loaded_entry_tag = Ash.get!(EntryTag, entry_tag.id, actor: partner)
      assert loaded_entry_tag.id == entry_tag.id

      # Partner should be able to update it
      {:ok, updated_entry_tag} =
        entry_tag
        |> Ash.Changeset.for_update(:update, %{role: nil}, actor: partner)
        |> Ash.update()

      assert is_nil(updated_entry_tag.role)

      # Partner should be able to destroy it
      :ok =
        updated_entry_tag
        |> Ash.Changeset.for_destroy(:destroy)
        |> Ash.destroy(actor: partner)

      assert {:error, %Ash.Error.Invalid{}} =
               Ash.get(EntryTag, entry_tag.id, actor: partner)
    end
  end

  describe "EntryTag listing and querying" do
    setup do
      user = generate(user())
      entry1 = generate(entry(actor: user))
      entry2 = generate(entry(actor: user))
      tag1 = generate(tag(actor: user))
      tag2 = generate(tag(actor: user))

      {:ok, entry_tag1} =
        EntryTag
        |> Ash.Changeset.for_create(
          :create,
          %{entry_id: entry1.id, tag_id: tag1.id, role: :main},
          actor: user
        )
        |> Ash.create()

      {:ok, entry_tag2} =
        EntryTag
        |> Ash.Changeset.for_create(
          :create,
          %{entry_id: entry2.id, tag_id: tag2.id},
          actor: user
        )
        |> Ash.create()

      %{
        user: user,
        entry1: entry1,
        entry2: entry2,
        tag1: tag1,
        tag2: tag2,
        entry_tag1: entry_tag1,
        entry_tag2: entry_tag2
      }
    end

    test "can list all EntryTags for a couple", %{user: user} do
      entry_tags = Ash.read!(EntryTag, actor: user)
      assert length(entry_tags) == 2
    end

    test "can filter EntryTags by entry", %{user: user, entry1: entry1} do
      entry_tags = Ash.Query.filter(EntryTag, entry_id == ^entry1.id) |> Ash.read!(actor: user)

      assert length(entry_tags) == 1
      assert hd(entry_tags).entry_id == entry1.id
    end

    test "can filter EntryTags by tag", %{user: user, tag1: tag1} do
      entry_tags = Ash.Query.filter(EntryTag, tag_id == ^tag1.id) |> Ash.read!(actor: user)

      assert length(entry_tags) == 1
      assert hd(entry_tags).tag_id == tag1.id
    end

    test "can filter EntryTags by role", %{user: user} do
      main_entry_tags = Ash.Query.filter(EntryTag, role == :main) |> Ash.read!(actor: user)

      assert length(main_entry_tags) == 1
      assert hd(main_entry_tags).role == :main

      nil_role_entry_tags = Ash.Query.filter(EntryTag, is_nil(role)) |> Ash.read!(actor: user)

      assert length(nil_role_entry_tags) == 1
      assert is_nil(hd(nil_role_entry_tags).role)
    end
  end
end