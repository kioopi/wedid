defmodule Wedid.Accounts do
  use Ash.Domain,
    otp_app: :wedid,
    extensions: [AshPhoenix]

  resources do
    resource Wedid.Accounts.Token

    resource Wedid.Accounts.User do
      define :invite_user, action: :invite, args: [:email, :couple_id]
    end

    resource Wedid.Accounts.Couple
  end
end
