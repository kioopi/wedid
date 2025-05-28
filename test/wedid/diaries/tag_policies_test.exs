defmodule Wedid.Diaries.TagPoliciesTest do
  use Wedid.DataCase, async: true

  alias Wedid.Accounts
  alias Wedid.Diaries
  # Unused: User, Couple, Tag, DiariesGenerator

  alias Wedid.Accounts.Generator, as: AccountsGenerator # Corrected
  # DiariesGenerator was unused, so removed the alias too.

  describe "Tag Resource Policies" do
    setup do
      user1 = generate(AccountsGenerator.user(%{email: "user1@example.com"}))
      user2 = generate(AccountsGenerator.user(%{email: "user2@example.com"})) # Belongs to a different couple by default

      tag_attrs_user1_couple = %{name: "Tag For User1", icon: "icon1", color: "color1"}

      %{user1: user1, user2: user2, tag_attrs_user1_couple: tag_attrs_user1_couple}
    end

    # === CREATE Action Tests ===
    test "user can create a tag for their own couple", %{user1: user1, tag_attrs_user1_couple: attrs} do
      assert {:ok, tag} = Diaries.create_tag(attrs, actor: user1)
      assert tag.name == attrs.name
      assert tag.couple_id == user1.couple_id
    end

    test "user cannot create a tag and assign it to another couple (implicitly, action sets couple_id)", %{user1: user1, user2: user2, tag_attrs_user1_couple: attrs} do
      # The :couple_id attribute is not accepted by the :create action for Tag, it's set by a change.
      # So, we don't need to (and shouldn't) pass it here.
      # The test is to ensure the actor's couple_id is used.
      attrs_for_actor1 = attrs # Use original attrs which don't have couple_id
      assert {:ok, tag} = Diaries.create_tag(attrs_for_actor1, actor: user1)
      assert tag.couple_id == user1.couple_id 
      assert tag.couple_id != user2.couple_id # Verifies it's not accidentally user2's couple
    end

    # === READ Action Tests ===
    test "user can read tags from their own couple", %{user1: user1, tag_attrs_user1_couple: attrs} do
      {:ok, tag} = Diaries.create_tag(attrs, actor: user1)
      assert {:ok, _read_tag} = Diaries.read_tag_by_id(tag.id, actor: user1)
    end

    test "user cannot read tags from another couple", %{user1: user1, user2: user2, tag_attrs_user1_couple: attrs} do
      {:ok, tag_for_user1} = Diaries.create_tag(attrs, actor: user1)
      # Attempt to read user1's tag as user2. Expect NotFound due to policy scope.
      # The error is wrapped in Ash.Error.Invalid
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} = Diaries.read_tag_by_id(tag_for_user1.id, actor: user2)
    end

    # === UPDATE Action Tests ===
    test "user can update tags from their own couple", %{user1: user1, tag_attrs_user1_couple: attrs} do
      {:ok, tag} = Diaries.create_tag(attrs, actor: user1)
      update_params = %{name: "Updated Tag Name"}
      assert {:ok, updated_tag} = Diaries.update_tag(tag, update_params, actor: user1)
      assert updated_tag.name == "Updated Tag Name"
    end

    test "user cannot update tags from another couple", %{user1: user1, user2: user2, tag_attrs_user1_couple: attrs} do
      {:ok, tag_for_user1} = Diaries.create_tag(attrs, actor: user1)
      update_params = %{name: "Attempted Update By User2"}
      # Attempt to update user1's tag as user2. Expect Forbidden.
      assert {:error, %Ash.Error.Forbidden{}} = Diaries.update_tag(tag_for_user1, update_params, actor: user2)
    end

    # === DESTROY Action Tests ===
    test "user can destroy tags from their own couple (if not linked)", %{user1: user1, tag_attrs_user1_couple: attrs} do
      {:ok, tag} = Diaries.create_tag(attrs, actor: user1) # Assumes tag is not linked to any entry for this test
      assert {:ok, _} = Diaries.destroy_tag(tag, actor: user1)
    end

    test "user cannot destroy tags from another couple", %{user1: user1, user2: user2, tag_attrs_user1_couple: attrs} do
      {:ok, tag_for_user1} = Diaries.create_tag(attrs, actor: user1)
      # Attempt to destroy user1's tag as user2. Expect Forbidden.
      assert {:error, %Ash.Error.Forbidden{}} = Diaries.destroy_tag(tag_for_user1, actor: user2)
    end
  end
end
