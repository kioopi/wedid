defmodule Wedid.Diaries.Entry do
  use Ash.Resource,
    otp_app: :wedid,
    domain: Wedid.Diaries,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication]

  require Ash.Query

  postgres do
    table "entries"
    repo Wedid.Repo
  end

  actions do
    defaults [:read, :destroy] # Removed update: [:content, :created_at]

    create :create do
      primary? true
      accept [:content, :created_at]
      argument :tags_in, {:array, :string}, default: [], allow_nil?: true
      argument :tags, {:array, :map}, default: [], allow_nil?: true # Added for manage_relationship
      change relate_actor(:user)
      change set_attribute(:couple_id, actor(:couple_id))
      change Wedid.Diaries.Entry.Changes.TransformTagInput
      change manage_relationship(:tags, type: :direct_control)
    end

    update :update do
      primary? true
      require_atomic? false
      accept [:content, :created_at]
      argument :tags_in, {:array, :string}, allow_nil?: true
      argument :tags, {:array, :map}, allow_nil?: true # Added for manage_relationship
      change Wedid.Diaries.Entry.Changes.TransformTagInput
      change manage_relationship(:tags, type: :direct_control)
    end

    read :list do
      prepare build(sort: [created_at: :asc], load: [user: [:display_name]])
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
    belongs_to :couple, Wedid.Accounts.Couple
    belongs_to :user, Wedid.Accounts.User

    many_to_many :tags, Wedid.Diaries.Tag do
      through Wedid.Diaries.EntryTag
      source_attribute_on_join_resource :entry_id
      destination_attribute_on_join_resource :tag_id
    end
  end
end
