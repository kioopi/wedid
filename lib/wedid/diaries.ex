defmodule Wedid.Diaries do
  use Ash.Domain,
    otp_app: :wedid,
    extensions: [AshPhoenix]

  resources do
    resource Wedid.Diaries.Entry do
      define :create_entry, action: :create, args: [:content]
      define :update_entry, action: :update, args: [:content]
      define :list_entries, action: :list
    end
  end
end
