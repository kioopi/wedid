defmodule Wedid.Accounts.CoupleTest do
  use Wedid.DataCase
  require Ash.Query

  alias Wedid.Accounts.{User, Generator}

  describe "Couple" do
    test "can list users" do
      user = Generator.generate(Generator.user())
      email = Faker.Internet.email()
      Wedid.Accounts.invite_user!(email, user.couple_id, actor: user)

      # users with the couple id exist
      users = Ash.Query.filter(User, couple_id == ^user.couple_id) |> Ash.read!(authorize?: false)
      assert length(users) == 2

      # users are correctly related with couple
      couple = Ash.load!(user.couple, :users, actor: user)
      assert length(couple.users) == 2

      # get emails from users
      assert Enum.map(couple.users, &to_string(&1.email)) == [to_string(user.email), email]
    end
  end
end
