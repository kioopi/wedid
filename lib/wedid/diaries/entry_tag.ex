defmodule Wedid.Diaries.EntryTag do
  @moduledoc """
  Join table resource representing the many-to-many relationship between entries and tags.

  EntryTag serves as the association table that connects diary entries with their assigned tags.
  It includes additional metadata such as the `role` field, which can be used to designate
  special tag relationships (e.g., `:main` for the primary tag of an entry).

  ## Role System

  The `role` attribute allows for different types of tag assignments:
  - `:main` - The primary tag for an entry (limited to one per entry)
  - `nil` or other atoms - Secondary or categorization tags

  ## Examples

      # The many-to-many relationship is typically managed through Entry actions
      # but EntryTag records are created automatically:

      # When creating an entry with tags
      iex> Wedid.Diaries.create_entry("My vacation story", %{tags: [tag1.id, tag2.id]}, actor: user)
      # This creates EntryTag records linking the entry to both tags

      # Direct EntryTag creation (less common)
      iex> Ash.create(Wedid.Diaries.EntryTag, %{
      ...>   entry_id: entry.id,
      ...>   tag_id: tag.id,
      ...>   role: :main
      ...> }, actor: user)

  ## Database Constraints

  - Unique constraint on `[:entry_id, :role]` where `role = :main`
  - Non-nullable foreign keys to both entries and tags
  - Cascade deletion when parent entry or tag is deleted

  ## Authorization

  EntryTag operations are protected by custom authorization logic:
  - Users must be part of the couple that owns both the entry and the tag
  - Cross-couple associations are prevented
  - Uses custom `SameCouple` policy check for create operations
  """
  use Ash.Resource,
    otp_app: :wedid,
    domain: Wedid.Diaries,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "entry_tags"
    repo Wedid.Repo

    identity_wheres_to_sql unique_main_tag_for_entry: "role = 'main'"
  end

  actions do
    defaults [:read, :destroy, create: [:entry_id, :tag_id, :role], update: [:role]]
  end

  policies do
    policy action(:create) do
      # User must be part of the couple that owns both the entry and tag
      authorize_if Wedid.Diaries.EntryTag.Checks.SameCouple
    end

    policy action(:read) do
      authorize_if expr(
                     entry.couple_id == ^actor(:couple_id) and tag.couple_id == ^actor(:couple_id)
                   )
    end

    policy action(:update) do
      authorize_if expr(
                     entry.couple_id == ^actor(:couple_id) and tag.couple_id == ^actor(:couple_id)
                   )
    end

    policy action(:destroy) do
      # User must be part of the couple that owns both the entry and tag
      authorize_if expr(
                     entry.couple_id == ^actor(:couple_id) and tag.couple_id == ^actor(:couple_id)
                   )
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :role, :atom do
      public? true
    end
  end

  relationships do
    belongs_to :entry, Wedid.Diaries.Entry, allow_nil?: false
    belongs_to :tag, Wedid.Diaries.Tag, allow_nil?: false
  end

  identities do
    identity :unique_main_tag_for_entry, [:entry_id, :role] do
      where expr(role == :main)
    end
  end
end
