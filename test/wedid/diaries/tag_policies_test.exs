defmodule Wedid.Diaries.TagPoliciesTest do
  use Wedid.DataCase, async: true

  alias Wedid.Accounts
  alias Wedid.Diaries

  import AccountsGenerator, only: [user: 0]
  import DiariesGenerator, only: [tag: 1]

  describe "create action" do
    test "user can create a tag for their own couple" do
      user = generate(user())
      assert {:ok, tag} = Diaries.create_tag(%{name: "tag"}, actor: user)
      assert tag.name == "tag"
      assert tag.couple_id == user.couple_id
    end

    test "user cannot create a tag and assign it to another couple (implicitly, action sets couple_id)" do
      user = generate(user())
      other = generate(user())

      assert {:error, %Ash.Error.Invalid{}} =
               Diaries.create_tag(%{name: "x", couple_id: other.couple_id}, actor: user)
    end

    test "not possible to create tag without actor" do
      assert {:error, %Ash.Error.Forbidden{}} =
               Diaries.create_tag(%{name: "x"})
    end
  end

  describe "read action" do
    test "user can read tags from their own couple" do
      user = generate(user())
      tag = generate(tag(actor: user))

      assert {:ok, _read_tag} = Diaries.read_tag_by_id(tag.id, actor: user)
    end

    test "user cannot read tags from another couple" do
      user = generate(user())
      other = generate(user())
      tag = generate(tag(actor: user))

      # Attempt to read user's tag as user2. Expect NotFound due to policy scope.
      # The error is wrapped in Ash.Error.Invalid
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Diaries.read_tag_by_id(tag.id, actor: other)
    end
  end

  describe "update action" do
    test "user can update tags from their own couple" do
      user = generate(user())
      tag = generate(tag(actor: user))

      assert {:ok, updated_tag} =
               Diaries.update_tag(tag, %{name: "Updated Tag Name"}, actor: user)

      assert updated_tag.name == "Updated Tag Name"
    end

    test "user cannot update tags from another couple" do
      user = generate(user())
      other = generate(user())
      tag = generate(tag(actor: user))

      update_params = %{name: "Attempted Update By User2"}
      # Attempt to update user1's tag as user2. Expect Forbidden.
      assert {:error, %Ash.Error.Forbidden{}} =
               Diaries.update_tag(tag, update_params, actor: other)
    end
  end

  describe "destroy action" do
    # === DESTROY Action Tests ===
    test "user can destroy tags from their own couple (if not linked)" do
      user = generate(user())
      tag = generate(tag(actor: user))
      assert :ok = Diaries.destroy_tag(tag, actor: user)
    end

    test "user cannot destroy tags from another couple" do
      user = generate(user())
      other = generate(user())
      tag = generate(tag(actor: user))

      assert {:error, %Ash.Error.Forbidden{}} = Diaries.destroy_tag(tag, actor: other)
    end

    test "cannot destroy tag that is associated to entry" do
      user = generate(user())
      tag = generate(tag(actor: user))

      Diaries.create_entry!("Test Entry", %{tags: [tag.id]}, actor: user)

      assert {:error, %Ash.Error.Invalid{}} = Diaries.destroy_tag(tag, actor: user)
    end
  end
end
