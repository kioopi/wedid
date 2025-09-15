defmodule Wedid.Accounts do
  use Ash.Domain,
    otp_app: :wedid,
    extensions: [AshPhoenix]

  resources do
    resource Wedid.Accounts.Token

    resource Wedid.Accounts.User do
      define :invite_user, action: :invite, args: [:email, :couple_id]
      define :list_users, action: :read
      define :update_user_profile, action: :update_profile, args: [:name]
      define :change_password, action: :change_password
      # Added this line
      define :get_user!, action: :read, get_by: [:id]
    end

    resource Wedid.Accounts.Couple
  end
end
