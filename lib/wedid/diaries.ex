defmodule Wedid.Diaries do
  @moduledoc """
   Domain for managing diary entries and their organization system.

   The Diaries domain provides the core functionality for couples to create, organize,
   and manage their shared diary entries through a flexible tagging system.

   ## Core Resources

   - **Entry** - Individual diary entries with content, timestamps, and tag associations
   - **Tag** - Organizational labels that couples can create and assign to entries


   ## Code Interface Functions

   ### Entry Management
   - `create_entry/2` - Create a new diary entry with optional tags
   - `update_entry/2` - Update entry content and/or tag assignments
   - `list_entries/1` - List all entries for a couple with preloaded tags
   - `read_entry_by_id/2` - Retrieve a specific entry by ID

   ### Tag Management
   - `create_tag/2` - Create a new tag for the couple
   - `update_tag/2` - Update tag properties (name, icon, color)
   - `read_tag_by_id/2` - Retrieve a specific tag by ID
   - `destroy_tag/2` - Delete a tag (with validation for entry associations)

   ## Examples

       # Create an entry with tags
       iex> Wedid.Diaries.create_entry("Amazing day!", %{tags: [tag1.id, tag2.id]}, actor: user)
       {:ok, %Entry{content: "Amazing day!", tags: [%Tag{}, %Tag{}]}}

       # Create a tag for organization
       iex> Wedid.Diaries.create_tag(%{name: "Holiday", color: "#ff0000"}, actor: user)
       {:ok, %Tag{name: "Holiday", color: "#ff0000"}}

       # List entries with tags preloaded
       iex> Wedid.Diaries.list_entries(actor: user)
       {:ok, [%Entry{tags: [%Tag{}], user: %User{}}]}
  """
  use Ash.Domain,
    otp_app: :wedid,
    extensions: [AshPhoenix]

  resources do
    resource Wedid.Diaries.Entry do
      define :create_entry, action: :create, args: [:content]
      define :update_entry, action: :update
      define :list_entries, action: :list
      define :read_entry_by_id, action: :read, get_by: [:id]
    end

    resource Wedid.Diaries.Tag do
      define :create_tag, action: :create
      define :destroy_tag, action: :destroy
      define :read_tag_by_id, action: :read, get_by: [:id]
      define :update_tag, action: :update
    end

    resource Wedid.Diaries.EntryTag
  end
end
