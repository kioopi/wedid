defmodule Wedid.Diaries.EntryTag do
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
