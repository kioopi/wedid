defmodule Wedid.Diaries.EntryTagIdentitiesTest do
  use Wedid.DataCase, async: true

  alias Wedid.Accounts
  alias Wedid.Diaries
  # Unused: User, Couple, Tag, Entry, EntryTag

  alias Wedid.Accounts.Generator, as: AccountsGenerator # Corrected
  alias Wedid.Diaries.Generator, as: DiariesGenerator # Corrected

  describe "EntryTag :main role uniqueness identity" do
    setup do
      user = generate(AccountsGenerator.user())
      entry = generate(DiariesGenerator.entry(actor: user)) # Create an entry for the user
      {:ok, tag1} = Diaries.create_tag(%{name: "Tag Alpha", color: "red"}, actor: user)
      {:ok, tag2} = Diaries.create_tag(%{name: "Tag Beta", color: "blue"}, actor: user)
      %{user: user, entry: entry, tag1: tag1, tag2: tag2}
    end

    test "cannot assign a second tag as :main to the same entry", %{user: user, entry: entry, tag1: tag1, tag2: tag2} do
      # 1. Link tag1 as :main - this should succeed
      link_tag1_attrs = %{tags_in: [tag1.id]} # TransformTagInput will set role to :main
      {:ok, updated_entry_with_tag1} = Diaries.update_entry(entry, link_tag1_attrs, actor: user)

      # Verify tag1 is linked (and implicitly has role :main)
      loaded_entry1 = Diaries.read_entry_by_id!(updated_entry_with_tag1.id, actor: user, load: [:tags])
      assert Enum.any?(loaded_entry1.tags, &(&1.id == tag1.id))
      # We could also check the EntryTag record directly if needed:
      # {:ok, entry_tag1_link} = Ash.get!(EntryTag, actor: user, filter: [entry_id: entry.id, tag_id: tag1.id])
      # assert entry_tag1_link.role == :main

      # 2. Attempt to link tag2 also as :main.
      # The TransformTagInput will make its role :main.
      # The unique identity on EntryTag (for entry_id, role when role == :main) should prevent this.
      # manage_relationship with :direct_control will try to create two EntryTag records with role: :main for the same entry.
      link_both_tags_attrs = %{tags_in: [tag1.id, tag2.id]}

      case Diaries.update_entry(updated_entry_with_tag1, link_both_tags_attrs, actor: user) do
        {:error, changeset} ->
          # We expect an error due to the unique identity on EntryTag.
          # This error might be bubbled up to the Entry changeset.
          # The error is often an :invalid_change or :invalid_relationship type.
          # Looking for specifics related to the identity or uniqueness constraint violation.
          # Example check (actual error structure might vary):
          found_identity_error = Enum.any?(changeset.errors, fn error ->
            # Check if error message or details mention the identity or uniqueness.
            # This could be a generic "is invalid" on :tags, or a more specific error.
            # Ash often surfaces identity errors as :invalid_attribute on the field that caused it,
            # or as a :base error on the changeset of the resource with the identity.
            # Since it's on EntryTag, it might be nested.
            # For now, a general check for "unique" or the identity name.
            error.message =~ ~r/unique_main_tag_for_entry/i ||
            error.message =~ ~r/violates unique constraint/i ||
            (error.field == :tags && error.message =~ ~r/invalid/i) ||
            # Check for nested errors if possible (depends on error structure)
            (is_list(error.errors) && Enum.any?(error.errors, &(&1.message =~ ~r/unique_main_tag_for_entry/i)))
          end)
          assert found_identity_error, "Expected an error due to unique_main_tag_for_entry identity, got: #{inspect(changeset.errors)}"

        {:ok, _} ->
          flunk("Should not have allowed linking a second tag as :main to the same entry")

        other_error ->
          flunk("Unexpected error: #{inspect(other_error)}")
      end

      # 3. Verify that only the first tag (or one tag) remains linked as :main
      # This depends on whether the entire update failed or only the conflicting part.
      # Given it's an identity on EntryTag, the transaction for update_entry should roll back.
      final_loaded_entry = Diaries.read_entry_by_id!(entry.id, actor: user, load: [:tags])
      assert length(final_loaded_entry.tags) == 1, "Should only have one tag linked after failed update"
      assert hd(final_loaded_entry.tags).id == tag1.id, "The originally linked tag should still be there"
    end
  end
end
