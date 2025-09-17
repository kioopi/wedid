defmodule Wedid.Accounts.User.ProfilePicture do
  use Ash.Resource.Calculation

  # Optional callback that verifies the passed in options (and optionally transforms them)
  @impl true
  def init(opts) do
    {:ok, opts}
  end

  @impl true
  def calculate(users, _opts, _args) do
    Enum.map(users, fn user ->
      to_string(user.email) |> Exgravatar.gravatar_url(s: 40, d: "404")
    end)
  end
end
