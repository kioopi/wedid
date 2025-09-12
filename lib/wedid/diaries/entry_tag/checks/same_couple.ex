defmodule Wedid.Diaries.EntryTag.Checks.SameCouple do
  @moduledoc """
  Custom policy check that ensures both entry and tag belong to the same couple as the actor.

  This check is used in EntryTag authorization to prevent users from creating associations
  between entries and tags that don't belong to their couple. It provides an additional
  layer of security beyond the basic couple-scoped policies on individual resources.

  ## Purpose

  While individual Entry and Tag resources have their own couple-scoped authorization,
  this check ensures that when creating an EntryTag association, both the entry and tag
  belong to the actor's couple. This prevents scenarios where a user might try to:

  - Associate their entry with another couple's tag
  - Associate another couple's entry with their tag
  - Create cross-couple tag relationships

  ## Implementation Details

  The check operates during the create action on EntryTag changesets by:

  1. Extracting the `entry_id` and `tag_id` from the changeset
  2. Loading both the entry and tag records (bypassing authorization)
  3. Verifying both resources have the same `couple_id` as the actor
  4. Returning `true` only if all couple IDs match

  ## Examples

      # This check is automatically used in EntryTag policies:
      policy action(:create) do
        authorize_if Wedid.Diaries.EntryTag.Checks.SameCouple
      end

      # The check will pass when:
      # - Actor belongs to couple A
      # - Entry belongs to couple A  
      # - Tag belongs to couple A

      # The check will fail when:
      # - Actor belongs to couple A
      # - Entry belongs to couple B (different couple)
      # - Tag belongs to couple A

  ## Error Handling

  If either the entry or tag cannot be loaded, the check returns `false`,
  effectively denying the operation. This ensures that invalid references
  are caught and handled gracefully.
  """
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_opts) do
    "entry and tag belong to the same couple as the actor"
  end

  @impl true
  def match?(actor, %{changeset: changeset}, _opts) do
    entry_id = Ash.Changeset.get_attribute(changeset, :entry_id)
    tag_id = Ash.Changeset.get_attribute(changeset, :tag_id)
    actor_couple_id = actor.couple_id

    # Check if both entry and tag belong to the actor's couple
    with {:ok, entry} <- Ash.get(Wedid.Diaries.Entry, entry_id, authorize?: false),
         {:ok, tag} <- Ash.get(Wedid.Diaries.Tag, tag_id, authorize?: false) do
      entry.couple_id == actor_couple_id && tag.couple_id == actor_couple_id
    else
      _ -> false
    end
  end

  # Handle case when not in create context
  def match?(_, _, _), do: false
end
