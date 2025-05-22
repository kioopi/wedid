defmodule Wedid.Diaries do
  use Ash.Domain,
    otp_app: :wedid,
    extensions: [AshPhoenix]

  resources do
    resource Wedid.Diaries.Entry do
      define :create_entry, action: :create, args: [:content, :created_at]
    end
  end
end
