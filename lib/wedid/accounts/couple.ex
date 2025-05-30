defmodule Wedid.Accounts.Couple do
  use Ash.Resource, otp_app: :wedid, domain: Wedid.Accounts, data_layer: AshPostgres.DataLayer

  alias Wedid.Accounts.User

  postgres do
    table "couples"
    repo Wedid.Repo
  end

  actions do
    defaults [:read, create: [:name]]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      public? true
    end

    timestamps()
  end

  relationships do
    has_many :users, User
  end

  aggregates do
    count :user_count, :users
  end
end
