defmodule Wedid.Diaries.Entry do
  @moduledoc """
  Represents a diary entry within the couple's shared journal.

  Entries are the core content pieces of the diary application, allowing partners
  to record their thoughts, experiences, and memories. Each entry belongs to both
  a specific user (the author) and a couple (shared context).

  ## Examples

      # Create an entry without tags
      iex> Wedid.Diaries.create_entry("Today was amazing!", actor: user)
      {:ok, %Entry{content: "Today was amazing!", user_id: user_id}}

      # Create an entry with tags
      iex> Wedid.Diaries.create_entry("Vacation photos", %{tags: [holiday_tag.id, photo_tag.id]}, actor: user)
      {:ok, %Entry{content: "Vacation photos", tags: [%Tag{name: "Holiday"}, %Tag{name: "Photos"}]}}

      # Update entry tags
      iex> Wedid.Diaries.update_entry(entry, %{tags: [new_tag.id]}, actor: user)
      {:ok, %Entry{tags: [%Tag{name: "New Tag"}]}}
  """
  use Ash.Resource,
    otp_app: :wedid,
    domain: Wedid.Diaries,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication]

  require Ash.Query

  alias Wedid.Diaries
  alias Wedid.Accounts

  postgres do
    table "entries"
    repo Wedid.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:content, :created_at]
      argument :tags, {:array, :uuid}, allow_nil?: true
      change manage_relationship(:tags, type: :append)
      change relate_actor(:user)
      change set_attribute(:couple_id, actor(:couple_id))
    end

    update :update do
      primary? true
      require_atomic? false
      accept [:content, :created_at]
      argument :tags, {:array, :uuid}, allow_nil?: true
      change manage_relationship(:tags, type: :append_and_remove)
    end

    read :list do
      prepare build(sort: [created_at: :asc], load: [:tags, user: [:display_name]])
      filter expr(couple_id == ^actor(:couple_id))
    end
  end

  policies do
    policy action_type(:update) do
      authorize_if expr(couple_id == ^actor(:couple_id))
      authorize_if expr(user_id == ^actor(:id))
    end

    policy action_type(:destroy) do
      authorize_if expr(couple_id == ^actor(:couple_id))
      authorize_if expr(user_id == ^actor(:id))
    end

    policy action_type(:read) do
      authorize_if expr(couple_id == ^actor(:couple_id))
      authorize_if expr(user_id == ^actor(:id))
    end

    policy action_type(:create) do
      authorize_if actor_present()
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :content, :string do
      allow_nil? false
      public? true
    end

    attribute :created_at, :utc_datetime do
      allow_nil? false
      default &DateTime.utc_now/0
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :couple, Accounts.Couple
    belongs_to :user, Accounts.User

    many_to_many :tags, Diaries.Tag do
      through Diaries.EntryTag
      source_attribute_on_join_resource :entry_id
      destination_attribute_on_join_resource :tag_id
    end
  end
end
