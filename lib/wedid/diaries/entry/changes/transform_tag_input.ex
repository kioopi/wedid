defmodule Wedid.Diaries.Entry.Changes.TransformTagInput do
  @moduledoc """
  Legacy change module for transforming tag input data during entry creation and updates.

  ## ⚠️ Deprecation Notice

  This module is currently unused and maintained for historical reference only.
  The tag input transformation logic has been simplified to directly accept
  UUID arrays in entry actions, making this change unnecessary.

  ## Original Purpose

  This change was originally designed to transform the `:tags_in` argument
  (array of tag ID strings) into the format expected by `manage_relationship/2`:
  an array of maps with `tag_id` and `role` fields.

  ## Historical Implementation

  The change performed the following transformations:

  1. Retrieved the `:tags_in` argument from the changeset
  2. Filtered out blank/empty string values from form submissions
  3. Converted each tag ID into a map: `%{tag_id: id, role: :main}`
  4. Set the result as the `:tags` argument for relationship management

  ## Current Alternative

  Entry actions now directly accept a `:tags` argument as an array of UUIDs,
  which is simpler and more straightforward:

      # Old approach (using this change)
      argument :tags_in, {:array, :string}
      change TransformTagInput

      # New approach (current implementation)
      argument :tags, {:array, :uuid}

  ## Migration Path

  If you need to reintroduce complex tag input transformation:

  1. Update the entry actions to use `:tags_in` argument
  2. Add this change back to the action definitions
  3. Modify the UI forms to submit tag data in the expected format

  ## Examples

      # Historical usage (no longer active):
      create :create do
        argument :tags_in, {:array, :string}
        change TransformTagInput
        change manage_relationship(:tags, type: :direct_control)
      end

      # Current usage:
      create :create do
        argument :tags, {:array, :uuid}
        change manage_relationship(:tags, type: :append)
      end
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    input_key = :tags_in
    # This is the argument manage_relationship will use
    output_key = :tags

    # Get the :tags_in argument. It might be a list of IDs, nil (if explicitly passed),
    # or not present (in which case action default [] should apply, or get_argument returns :error).
    tag_id_list_input = Ash.Changeset.get_argument(changeset, input_key)

    # Ensure we are working with a list; if input was nil, convert to empty list.
    actual_tag_id_list = tag_id_list_input || []

    # Filter out any blank strings that might come from form submissions
    processed_tag_ids =
      Enum.reject(actual_tag_id_list, fn id_string ->
        is_nil(id_string) || String.trim(id_string) == ""
      end)

    tags_data_for_relationship =
      Enum.map(processed_tag_ids, fn tag_id ->
        # Assuming tag_ids from multi-select are already strings (e.g., UUIDs)
        %{tag_id: tag_id}
      end)

    Ash.Changeset.force_set_argument(changeset, output_key, tags_data_for_relationship)
  end
end
