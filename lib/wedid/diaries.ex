defmodule Wedid.Diaries do
  use Ash.Domain,
    otp_app: :wedid,
    extensions: [AshPhoenix]

  resources do
    resource Wedid.Diaries.Entry do
      define :create_entry, action: :create, args: [:content, :created_at]
      define :list_entries, action: :list
      define :update_entry, action: :update
      define :read_entry_by_id!, action: :read, get_by: [:id] # Removed bang?: true
    end

    resource Wedid.Diaries.Tag do
      define :create_tag, action: :create
      define :destroy_tag, action: :destroy
      define :read_tag_by_id, action: :read, get_by: [:id]
      define :update_tag, action: :update # Added this line
    end
    resource Wedid.Diaries.EntryTag
  end
end
