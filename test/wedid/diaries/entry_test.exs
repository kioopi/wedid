defmodule Wedid.Diaries.EntryTest do
  use Wedid.DataCase

  require Ash.Query

  @valid_content "This is a test entry content"

  describe "Entry" do
    setup do
      # Create a user for testing
      user = generate(AccountsGenerator.user())
      partner = Wedid.Accounts.invite_user!(Faker.Internet.email(), actor: user)

      # Create another user with different couple
      another_user = generate(AccountsGenerator.user())

      %{
        user: user,
        partner: partner,
        couple_id: user.couple_id,
        other_user: another_user
      }
    end

    test "user can create entry for their couple", %{user: user} do
      entry_attrs = %{
        content: @valid_content,
        created_at: DateTime.utc_now()
      }

      assert {:ok, entry} =
               Entry
               |> Ash.Changeset.for_create(:create, entry_attrs, actor: user)
               |> Ash.create()

      # Verify entry was created with correct attributes
      assert entry.content == @valid_content
      assert entry.user_id == user.id
      assert entry.couple_id == user.couple_id
    end

    test "user can update entry", %{user: user} do
      entry = generate(DiariesGenerator.entry(actor: user))

      entry_attrs = %{
        content: @valid_content,
        created_at: ~U[2023-10-01 12:00:00Z]
      }

      entry =
        Ash.Changeset.for_update(entry, :update, entry_attrs, actor: user)
        |> Ash.update!()

      assert entry.content == @valid_content
      assert entry.created_at == ~U[2023-10-01 12:00:00Z]
    end

    test "partner can update entry", %{user: user, partner: partner} do
      entry = generate(DiariesGenerator.entry(actor: user))

      entry_attrs = %{
        content: @valid_content,
        created_at: ~U[2023-10-01 12:00:00Z]
      }

      {:ok, entry} =
        entry
        |> Ash.Changeset.for_update(:update, entry_attrs, actor: partner)
        |> Ash.update()

      assert entry.content == @valid_content
      assert entry.created_at == ~U[2023-10-01 12:00:00Z]
    end

    test "other user can not update entry", %{user: user, other_user: other_user} do
      entry = generate(DiariesGenerator.entry(actor: user))

      entry_attrs = %{
        content: @valid_content,
        created_at: ~U[2023-10-01 12:00:00Z]
      }

      {:error, %Ash.Error.Forbidden{}} =
        entry
        |> Ash.Changeset.for_update(:update, entry_attrs, actor: other_user)
        |> Ash.update()
    end

    test "entry's couple relationship cannot be updated", %{user: user} do
      entry = generate(DiariesGenerator.entry(actor: user))

      # Try to update the couple_id
      # This should fail since couple_id is not accepted in the update action
      assert {:error, %Ash.Error.Invalid{}} =
               entry
               |> Ash.Changeset.for_update(:update, %{couple_id: Ash.UUID.generate()})
               |> Ash.update()
    end

    test "entry's user relationship cannot be updated", %{user: user} do
      entry = generate(DiariesGenerator.entry(actor: user))

      assert {:error, %Ash.Error.Invalid{}} =
               entry
               |> Ash.Changeset.for_update(:update, %{user_id: Ash.UUID.generate()})
               |> Ash.update()
    end
  end

  describe "Entry authorization" do
    setup do
      # Create a user for testing
      user1 = generate(AccountsGenerator.user())

      # Create another user with different couple
      user2 = generate(AccountsGenerator.user())

      entry = generate(DiariesGenerator.entry(actor: user1))

      %{
        user: user1,
        other_user: user2,
        entry: entry
      }
    end

    test "users can read entries", %{user: user, entry: entry} do
      fetched_entry = Ash.get!(Entry, entry.id, actor: user)
      assert fetched_entry.id == entry.id
    end

    test "other users can not read entries", %{other_user: other_user, entry: entry} do
      assert {:error, _} = Ash.get(Entry, entry.id, actor: other_user)
    end
  end
end
