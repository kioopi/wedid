defmodule Wedid.Accounts.Generator do
  use Ash.Generator

  # Generator for a User resource
  # Assumes Wedid.Accounts.User resource exists with :register_with_password action
  # Assumes :email, :password, :password_confirmation are accepted arguments [2]
  def user(opts \\ []) do
    changeset_generator(
      Wedid.Accounts.User,
      :register_with_password,
      defaults: [
        email: sequence(:user_email, &"user#{&1}@example.com"),
        password: "password",
        password_confirmation: "password",
        confirmed_at: ~U[2025-05-13 00:00:00Z]
      ],
      authorize?: false,
      overrides: opts
    )
  end
end
