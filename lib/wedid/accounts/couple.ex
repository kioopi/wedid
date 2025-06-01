defmodule Wedid.Accounts.Couple do
  @moduledoc """
  Represents a couple in the diary application.

  A couple is the core organizational unit that groups users and their shared content.
  Each couple has their own isolated space for diary entries, tags, and other shared
  resources.
  """
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
    has_many :tags, Wedid.Diaries.Tag
  end

  aggregates do
    count :user_count, :users
  end
end
