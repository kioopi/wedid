defmodule WedidWeb.EntryLive.Form do
  @moduledoc """
  LiveView for creating and editing diary entries with tag assignment.

  This form provides a comprehensive interface for managing diary entries,
  including content editing, timestamp management, and tag assignment from
  the couple's shared tag library.
  """
  use WedidWeb, :live_view

  on_mount {WedidWeb.LiveUserAuth, :live_user_required}

  alias Wedid.Diaries

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="min-h-screen bg-gradient-to-b from-base-100 to-base-200">
        <div class="container mx-auto px-4 py-8 max-w-md">
          <.header>
            <div class="flex items-center gap-2">
              <.heroicon name="hero-pencil-square" class="size-6 text-primary" />
              <span>{@page_title}</span>
            </div>
            <:subtitle>{gettext("Share your thoughts and moments with your partner")}</:subtitle>
          </.header>

          <div class="card bg-base-100 shadow-lg mt-6">
            <div class="card-body">
              <.form for={@form} id="entry-form" phx-change="validate" phx-submit="save">
                <.input
                  field={@form[:content]}
                  type="textarea"
                  label={gettext("Content")}
                  class="textarea textarea-primary"
                />
                <.input
                  field={@form[:tags]}
                  type="select"
                  label={gettext("Select Tag")}
                  options={
                    Enum.map(@available_tags, fn tag ->
                      display_name = if tag.icon, do: "#{tag.icon} #{tag.name}", else: tag.name
                      {display_name, tag.id}
                    end)
                  }
                  class="select select-primary"
                  value={tag_value(@form[:tags].value)}
                />
                <.input
                  field={@form[:created_at]}
                  type="datetime-local"
                  label={gettext("Created at")}
                  class="input input-primary"
                />

                <div class="flex justify-end gap-2 mt-6">
                  <.button navigate={return_path(@return_to, @entry)} class="btn btn-ghost">
                    <.heroicon name="hero-x-mark" class="size-4 mr-1" /> {gettext("Cancel")}
                  </.button>
                  <.button phx-disable-with={gettext("Saving...")} variant="primary">
                    <.heroicon name="hero-check" class="size-4 mr-1" /> {gettext("Save Entry")}
                  </.button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    current_user = socket.assigns.current_user
    current_user = Ash.load!(socket.assigns.current_user, [couple: [:tags]], actor: current_user)
    available_tags = current_user.couple.tags || []
    socket = assign(socket, :available_tags, available_tags)

    entry =
      case params["id"] do
        nil -> nil
        id -> Ash.get!(Wedid.Diaries.Entry, id, actor: current_user, load: [:tags])
      end

    action = if is_nil(entry), do: gettext("New"), else: gettext("Edit")
    page_title = action <> " " <> gettext("Entry")

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(entry: entry)
     |> assign(:page_title, page_title)
     |> assign_form()}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  @impl true
  def handle_event("validate", %{"form" => %{"tags" => tags}} = params, socket)
      when not is_list(tags) do
    # Convert single tag selection to array format expected by the backend
    # This handles the case where the form sends a single value instead of an array
    handle_event("validate", put_in(params["form"]["tags"], [tags]), socket)
  end

  def handle_event("validate", %{"form" => entry_params}, socket) do
    # Real-time validation of form fields as user types
    # Provides immediate feedback on validation errors
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, entry_params))}
  end

  # TODO: Move form data transformation to a dedicated change module
  # This pattern could be extracted to a reusable change for better organization
  def handle_event("save", %{"form" => %{"tags" => tags}} = params, socket)
      when not is_list(tags) do
    # Ensure tags are always in array format for relationship management
    # Single select dropdowns send strings, but backend expects arrays
    handle_event("save", put_in(params["form"]["tags"], [tags]), socket)
  end

  def handle_event("save", %{"form" => %{"created_at" => ""}} = params, socket) do
    # Remove empty created_at field to use default timestamp
    # Empty datetime inputs should fall back to "now"
    handle_event("save", update_in(params["form"], &Map.delete(&1, "created_at")), socket)
  end

  def handle_event("save", %{"form" => entry_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: entry_params) do
      {:ok, entry} ->
        notify_parent({:saved, entry})

        socket =
          socket
          |> put_flash(
            :info,
            gettext("Entry %{action}d successfully", action: socket.assigns.form.source.type)
          )
          |> push_navigate(to: return_path(socket.assigns.return_to, entry))

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{entry: entry}} = socket) do
    form =
      if entry do
        Diaries.form_to_update_entry(
          entry,
          actor: socket.assigns.current_user
        )
      else
        Diaries.form_to_create_entry(actor: socket.assigns.current_user)
      end

    assign(socket, form: to_form(form))
  end

  defp return_path("index", _entry), do: ~p"/entries"
  defp return_path("show", entry), do: ~p"/entries/#{entry.id}"

  # Helper function to extract tag value for form display.
  defp tag_value([tag | _]), do: tag_value(tag)
  defp tag_value(%Diaries.Tag{id: id}), do: id
  defp tag_value(id), do: id
end
