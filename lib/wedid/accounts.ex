defmodule Wedid.Accounts do
  use Ash.Domain,
    otp_app: :wedid

  resources do
    resource Wedid.Accounts.Token
    resource Wedid.Accounts.User
    resource Wedid.Accounts.Couple
  end
end
