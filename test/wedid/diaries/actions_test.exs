defmodule Wedid.Diaries.ActionsTest do
  use Wedid.DataCase

  import ExUnitProperties
  import Ash.Generator, only: [generate: 1]
  import Wedid.Accounts.Generator, only: [user: 1]
  alias Wedid.Diaries
  alias Diaries.Entry

  describe "create_entry" do
    property "accepts all valid input" do
      user = generate(user())

      check all(input <- Ash.Generator.action_input(Entry, :create)) do
        {content, params} = Map.pop!(input, :content)

        assert Diaries.changeset_to_create_entry(
                 content,
                 params,
                 actor: user
               ).valid?
      end
    end

    property "succeeds with valid input" do
      user = generate(user())

      check all(input <- Ash.Generator.action_input(Entry, :create)) do
        {content, params} = Map.pop!(input, :content)

        assert Diaries.create_entry!(content, params, actor: user)
      end
    end
  end
end
