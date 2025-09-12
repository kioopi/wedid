defmodule Wedid.Accounts.User.CreateCouple do
  @moduledoc """
  Used to create a couple when a user registers.
  This is a custom change because the :register_with_password action of the
  user takes no :couple argument as it is not required because the couple takes
  no arguments.
  """
  use Ash.Resource.Change

  @impl true
  def init(opts) do
    {:ok, opts}
  end

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.manage_relationship(changeset, :couple, %{}, type: :create)
  end
end
