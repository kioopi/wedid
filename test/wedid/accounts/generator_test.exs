defmodule Wedid.Accounts.GeneratorTest do
  use Wedid.DataCase
  require Ash.Query

  describe "Accounts Generator" do
    test "can create users" do
      user = generate(AccountsGenerator.user())

      assert to_string(user.email) =~ ~r|user.+@example\.com|
    end

    test "accepts email override" do
      user = generate(AccountsGenerator.user(email: "olaf@hotmail.com"))

      assert to_string(user.email) == "olaf@hotmail.com"
    end
  end
end
