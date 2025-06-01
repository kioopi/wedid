defmodule Wedid.Diaries.EntryTag.Checks.SameCouple do
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_opts) do
    "entry and tag belong to the same couple as the actor"
  end

  @impl true
  def match?(actor, %{changeset: changeset}, _opts) do
    entry_id = Ash.Changeset.get_attribute(changeset, :entry_id)
    tag_id = Ash.Changeset.get_attribute(changeset, :tag_id)
    actor_couple_id = actor.couple_id

    # Check if both entry and tag belong to the actor's couple
    with {:ok, entry} <- Ash.get(Wedid.Diaries.Entry, entry_id, authorize?: false),
         {:ok, tag} <- Ash.get(Wedid.Diaries.Tag, tag_id, authorize?: false) do
      entry.couple_id == actor_couple_id && tag.couple_id == actor_couple_id
    else
      _ -> false
    end
  end

  # Handle case when not in create context
  def match?(_, _, _), do: false
end