defmodule WedidWeb.Couple.TagManagementComponent do
  @moduledoc """
  LiveComponent for comprehensive tag management within a couple's context.

  Provides full CRUD operations for tags including:
  - Creating tags with icons, names, and colors
  - Editing existing tags inline
  - Deleting tags with confirmation
  - Display tags with visual indicators
  """
  use WedidWeb, :live_component

  alias Wedid.Diaries

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{tags: _tags, current_user: current_user} = assigns, socket) do
    new_tag_form = Diaries.form_to_create_tag(actor: current_user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:new_tag_form, to_form(new_tag_form))
     |> assign(:editing_tag, nil)}
  end

  @impl true
  def handle_event("validate_tag", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.new_tag_form, params)
    {:noreply, assign(socket, :new_tag_form, form)}
  end

  @impl true
  def handle_event("create_tag", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.new_tag_form, params: params) do
      {:ok, _tag} ->
        new_tag_form = Diaries.form_to_create_tag(actor: socket.assigns.current_user)

        send(self(), {:tag_created, "Tag created successfully."})

        {:noreply,
         socket
         |> assign(:new_tag_form, to_form(new_tag_form))}

      {:error, form} ->
        {:noreply,
         socket
         |> assign(:new_tag_form, form)}
    end
  end

  @impl true
  def handle_event("edit_tag", %{"id" => id}, socket) do
    tag = Enum.find(socket.assigns.tags, &(&1.id == id))
    edit_form = Diaries.form_to_update_tag(tag, actor: socket.assigns.current_user)

    {:noreply, assign(socket, :editing_tag, %{tag: tag, form: to_form(edit_form)})}
  end

  @impl true
  def handle_event("validate_edit_tag", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.editing_tag.form, params)
    editing_tag = Map.put(socket.assigns.editing_tag, :form, form)
    {:noreply, assign(socket, :editing_tag, editing_tag)}
  end

  @impl true
  def handle_event("update_tag", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.editing_tag.form, params: params) do
      {:ok, _tag} ->
        send(self(), {:tag_updated, "Tag updated successfully."})

        {:noreply,
         socket
         |> assign(:editing_tag, nil)}

      {:error, form} ->
        editing_tag = Map.put(socket.assigns.editing_tag, :form, form)

        {:noreply,
         socket
         |> assign(:editing_tag, editing_tag)}
    end
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, :editing_tag, nil)}
  end

  @impl true
  def handle_event("delete_tag", %{"id" => id}, socket) do
    tag = Enum.find(socket.assigns.tags, &(&1.id == id))

    case Diaries.destroy_tag(tag, actor: socket.assigns.current_user) do
      :ok ->
        send(self(), {:tag_deleted, "Tag deleted successfully."})
        {:noreply, socket}

      {:error, _reason} ->
        send(self(), {:tag_error, "Failed to delete tag."})
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"tag-management-#{@id}"} class="space-y-6">
      <div>
        <p class="text-sm text-base-content/70 mb-4">
          Create and manage tags to organize your journal entries. Use emojis or unicode characters as icons.
        </p>

        <.form
          for={@new_tag_form}
          phx-change="validate_tag"
          phx-submit="create_tag"
          phx-target={@myself}
          class="space-y-4"
          id="new-tag-form"
        >
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <.input
              field={@new_tag_form[:name]}
              type="text"
              label="Tag Name"
              placeholder="e.g., Holiday"
              id="new-tag-name"
            />
            <.input
              field={@new_tag_form[:icon]}
              type="text"
              label="Icon (optional)"
              placeholder="🏖️"
              id="new-tag-icon"
            />
            <.input
              field={@new_tag_form[:color]}
              type="color"
              label="Color (optional)"
              id="new-tag-color"
            />
          </div>

          <div class="flex justify-end">
            <.button type="submit" variant="primary" phx-disable-with="Creating...">
              Create Tag
            </.button>
          </div>
        </.form>
      </div>

      <div :if={length(@tags) > 0}>
        <h4 class="font-semibold mb-3">Existing Tags</h4>
        <div class="space-y-2">
          <%= for tag <- @tags do %>
            <div class="flex items-center justify-between p-3 bg-base-100 rounded-lg border">
              <div class="flex items-center gap-3">
                <span :if={tag.icon} class="text-lg">{tag.icon}</span>
                <span class="font-medium">{tag.name}</span>
                <span
                  :if={tag.color}
                  class="w-4 h-4 rounded-full border"
                  style={"background-color: #{tag.color}"}
                >
                </span>
              </div>

              <div class="flex gap-2">
                <%= if @editing_tag && @editing_tag.tag.id == tag.id do %>
                  <.button phx-click="cancel_edit" phx-target={@myself} class="btn-sm">
                    Cancel
                  </.button>
                <% else %>
                  <.button
                    phx-click="edit_tag"
                    phx-value-id={tag.id}
                    phx-target={@myself}
                    class="btn-sm"
                  >
                    Edit
                  </.button>
                  <.button
                    phx-click="delete_tag"
                    phx-value-id={tag.id}
                    phx-target={@myself}
                    class="btn-sm btn-error"
                    data-confirm="Are you sure you want to delete this tag?"
                  >
                    Delete
                  </.button>
                <% end %>
              </div>
            </div>

            <%= if @editing_tag && @editing_tag.tag.id == tag.id do %>
              <div class="ml-6 p-4 bg-base-200 rounded-lg">
                <.form
                  for={@editing_tag.form}
                  phx-change="validate_edit_tag"
                  phx-submit="update_tag"
                  phx-target={@myself}
                  class="space-y-4"
                  id={"edit-tag-form-#{@editing_tag.tag.id}"}
                >
                  <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <.input
                      field={@editing_tag.form[:name]}
                      type="text"
                      label="Tag Name"
                      id={"edit-tag-name-#{@editing_tag.tag.id}"}
                    />
                    <.input
                      field={@editing_tag.form[:icon]}
                      type="text"
                      label="Icon (optional)"
                      id={"edit-tag-icon-#{@editing_tag.tag.id}"}
                    />
                    <.input
                      field={@editing_tag.form[:color]}
                      type="color"
                      label="Color (optional)"
                      id={"edit-tag-color-#{@editing_tag.tag.id}"}
                    />
                  </div>

                  <div class="flex justify-end gap-2">
                    <.button type="button" phx-click="cancel_edit" phx-target={@myself}>
                      Cancel
                    </.button>
                    <.button type="submit" variant="primary" phx-disable-with="Updating...">
                      Update Tag
                    </.button>
                  </div>
                </.form>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
