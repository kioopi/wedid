defmodule Wedid.Diaries.Tag do
  @moduledoc """
  Represents a tag that can be assigned to diary entries for organization and categorization.

  Tags are scoped to couples, allowing partners to create shared tags for organizing
  their entries. Each tag can have a name, optional icon, and optional color for
  visual identification.

  ## Examples

      # Create a new tag for a couple
      iex> Wedid.Diaries.create_tag(%{name: "Holiday"}, actor: user)
      {:ok, %Tag{name: "Holiday", couple_id: couple_id}}

      # Create a tag with icon and color
      iex> Wedid.Diaries.create_tag(%{
      ...>   name: "Important",
      ...>   icon: "hero-star",
      ...>   color: "#ff0000"
      ...> }, actor: user)
      {:ok, %Tag{name: "Important", icon: "hero-star", color: "#ff0000"}}
  """
  use Ash.Resource,
    otp_app: :wedid,
    domain: Wedid.Diaries,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "tags"
    repo Wedid.Repo
  end

  actions do
    read :read do
      primary? true
    end

    update :update do
      primary? true
      accept [:name, :icon, :color]
    end

    create :create do
      primary? true
      accept [:name, :icon, :color]
      change set_attribute(:couple_id, actor(:couple_id))
    end

    destroy :destroy do
      primary? true
      #    validate {Ash.Changeset, :validate_associated_not_exists, [
      #      relationship_path: [:entries],
      #      message: "Cannot delete a tag that is currently assigned to entries."
      #    ]}
    end
  end

  policies do
    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action_type(:read) do
      authorize_if expr(couple_id == ^actor(:couple_id))
    end

    policy action_type(:update) do
      authorize_if expr(couple_id == ^actor(:couple_id))
    end

    policy action_type(:destroy) do
      authorize_if expr(couple_id == ^actor(:couple_id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :icon, :string do
      public? true
    end

    attribute :color, :string do
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :couple, Wedid.Accounts.Couple

    many_to_many :entries, Wedid.Diaries.Entry do
      through Wedid.Diaries.EntryTag
      source_attribute_on_join_resource :tag_id
      destination_attribute_on_join_resource :entry_id
    end
  end
end
