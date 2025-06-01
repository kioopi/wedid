defmodule Wedid.Diaries do
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
