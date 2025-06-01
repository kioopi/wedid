defmodule Wedid.Diaries.Entry.Changes.TransformTagInput do
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
