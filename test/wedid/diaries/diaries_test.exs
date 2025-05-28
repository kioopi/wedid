defmodule Wedid.Diaries.DiariesTest do
  use Wedid.DataCase

  require Ash.Query

  @valid_content "This is a test entry content"

  describe "create_entry" do
    test "creates an entry for a couple" do
      user = generate(AccountsGenerator.user())

      entry =
        Diaries.create_entry!(
          @valid_content,
          %{created_at: DateTime.utc_now()},
          actor: user
        )

      assert entry.content == @valid_content
      assert entry.couple_id == user.couple_id
    end
  end

  describe "list_entries" do
    test "list_entries of a couple" do
      user = generate(AccountsGenerator.user())
      generate(DiariesGenerator.entry(actor: user))

      entries = Diaries.list_entries!(actor: user)

      assert length(entries) == 1
      [first_entry] = entries

      # user is loaded
      assert first_entry.user.email == user.email
    end

    test "list_entries contains the display_name of the users" do
      user = generate(AccountsGenerator.user())
      generate(DiariesGenerator.entry(actor: user))

      user = Accounts.update_user_profile!(user, "james joice", actor: user)

      entries = Diaries.list_entries!(actor: user)

      assert length(entries) == 1
      [first_entry] = entries

      # user is loaded
      assert first_entry.user.display_name == "james joice"
    end

    test "list_entries with a query" do
      user = generate(AccountsGenerator.user())
      generate(DiariesGenerator.entry(actor: user))
      partner = Accounts.invite_user!(Faker.Internet.email(), user.couple_id, actor: user)
      generate(DiariesGenerator.entry(actor: partner))

      entries =
        Diaries.list_entries!(
          actor: user,
          query: Ash.Query.filter(Entry, user_id != ^user.id)
        )

      assert length(entries) == 1

      [first_entry] = entries
      # entry only contains the partner's entry
      assert first_entry.user.email == partner.email

      assert first_entry.user.display_name ==
               to_string(partner.email) |> String.split("@") |> List.first()
    end
  end
end
