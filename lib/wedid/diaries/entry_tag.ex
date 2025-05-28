defmodule Wedid.Diaries.EntryTag do
  use Ash.Resource,
    otp_app: :wedid,
    domain: Wedid.Diaries,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "entry_tags"
    repo Wedid.Repo

    identity_wheres_to_sql [
      unique_main_tag_for_entry: "role = 'main'"
    ]
  end

  identities do
    identity :unique_main_tag_for_entry, [:entry_id, :role] do
      where expr(role == :main)
    end
  end

  actions do
    defaults [:read, :destroy, create: [:role], update: [:role]]
  end

  policies do
    policy action(:create) do
      authorize_if relates_to_actor_via([:entry, :couple])
      authorize_if relates_to_actor_via([:tag, :couple])
    end

    policy action(:read) do
      authorize_if relates_to_actor_via([:entry, :couple])
      authorize_if relates_to_actor_via([:tag, :couple])
    end

    policy action(:update) do
      authorize_if relates_to_actor_via([:entry, :couple])
      authorize_if relates_to_actor_via([:tag, :couple])
    end

    policy action(:destroy) do
      # Only need to check one side, as unlinking primarily depends on rights to modify the "parent" (Entry)
      authorize_if relates_to_actor_via([:entry, :couple])
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :role, :atom do
      public? true
    end
  end

  relationships do
    belongs_to :entry, Wedid.Diaries.Entry
    belongs_to :tag, Wedid.Diaries.Tag
  end
end
