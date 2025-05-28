defmodule Wedid.Diaries.ActionsTest do
  use Wedid.DataCase

  import Ash.Generator, only: [generate: 1]
  import Wedid.Accounts.Generator, only: [user: 0]
  import Wedid.Diaries.Generator, only: [entry: 1]
  alias Wedid.Diaries

  describe "entries" do
    test "user can update their own entries" do
      user = generate(user())
      entry = generate(entry(actor: user))

      assert Diaries.can_update_entry?(user, entry, "Great day!")
    end

    test "others can not update others entries" do
      user = generate(user())
      other = generate(user())
      entry = generate(entry(actor: other))

      refute Diaries.can_update_entry?(user, entry, "Great day!")
    end

    test "others can update couples entries" do
      user = generate(user())
      entry = generate(entry(actor: user))
      partner = Accounts.invite_user!(Faker.Internet.email(), user.couple_id, actor: user)

      assert Diaries.can_update_entry?(partner, entry, "Great day!")
    end
  end
end
