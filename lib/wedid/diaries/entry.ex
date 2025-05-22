defmodule Wedid.Diaries.Entry do
  use Ash.Resource,
    otp_app: :wedid,
    domain: Wedid.Diaries,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication]

  postgres do
    table "entries"
    repo Wedid.Repo
  end

  actions do
    defaults [:read, :destroy, update: [:content, :created_at]]

    create :create do
      primary? true
      accept [:content, :created_at]
      change relate_actor(:user)
      change set_attribute(:couple_id, actor(:couple_id))
    end
  end

  policies do
    policy action_type(:update) do
      authorize_if expr(user_id == ^actor(:id))
      authorize_if expr(couple_id == ^actor(:couple_id))
    end

    policy action_type(:destroy) do
      authorize_if relates_to_actor_via(:couple)
      authorize_if expr(user_id == ^actor(:id))
    end

    policy action_type(:read) do
      authorize_if relates_to_actor_via(:couple)
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
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :couple, Wedid.Accounts.Couple
    belongs_to :user, Wedid.Accounts.User
  end
end
