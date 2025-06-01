defmodule WedidWeb.Couple.CoupleLive do
  @moduledoc """
  LiveView for managing couple information and shared resources.

  This LiveView provides the main interface for couples to manage their shared
  resources, including inviting partners and creating/managing tags for
  organizing diary entries.
  """
  use WedidWeb, :live_view
  import WedidWeb.CoreComponents
  alias Wedid.Diaries

  on_mount {WedidWeb.LiveUserAuth, :live_user_required}

  alias Wedid.Accounts

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok, current_user} =
      Ash.load(current_user, [couple: [:tags, users: [:display_name]]], actor: current_user)

    form = Accounts.form_to_invite_user(actor: current_user)
    tag_form = Diaries.form_to_create_tag(actor: current_user)

    if current_user.couple_id do
      {:ok,
       socket
       |> assign(:couple, current_user.couple)
       |> assign(:users, current_user.couple.users)
       |> assign(:tags, current_user.couple.tags)
       |> assign(:form, to_form(form))
       |> assign(:tag_form, to_form(tag_form))}
    else
      {:ok, socket |> put_flash(:error, "You need to be part of a couple") |> redirect(to: "/")}
    end
  end

  @impl true
  def handle_event("invite_partner", %{"form" => form_data}, socket) do
    current_user = socket.assigns.current_user
    form_data = Map.put(form_data, "couple_id", current_user.couple_id)

    case AshPhoenix.Form.submit(socket.assigns.form, params: form_data) do
      {:ok, _invited_user} ->
        # Fixme: new user shoud just be appended assigns.users
        {:ok, current_user} =
          Ash.load(current_user, [couple: [users: [:display_name]]], actor: current_user)

        users = current_user.couple.users

        {:noreply,
         socket
         |> assign(:users, users)
         |> push_event("hideModal", %{id: "invite-modal"})
         |> put_flash(:info, "Partner invitation sent successfully!")}

      {:error, form} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to send partner invitation")
         |> assign(:form, form)}
    end
  end

  @impl true
  def handle_event("validate_partner_email", %{"form" => form_data}, socket) do
    socket =
      update(socket, :form, fn form ->
        AshPhoenix.Form.validate(form, form_data)
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_tag", %{"form" => tag_params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.tag_form, tag_params)
    {:noreply, assign(socket, tag_form: form)}
  end

  @impl true
  def handle_event("save_tag", %{"form" => tag_params}, socket) do
    current_user = socket.assigns.current_user

    case AshPhoenix.Form.submit(socket.assigns.tag_form, params: tag_params, actor: current_user) do
      {:ok, new_tag} ->
        tag_form = Diaries.form_to_create_tag(actor: current_user)

        socket =
          socket
          |> assign(tags: [new_tag | socket.assigns.tags])
          |> assign(tag_form: to_form(tag_form))
          |> put_flash(:info, "Tag '#{new_tag.name}' created successfully!")
          |> push_event("hideModal", %{id: "tag-modal"})

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, tag_form: form)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto p-6">
        <.header>
          Your Couple: {@couple.name}
          <:actions>
            <.button phx-click={show_modal("invite-modal")}>
              <.heroicon name="hero-user-plus" class="size-4 mr-2" /> Invite Partner
            </.button>
          </:actions>
        </.header>

        <div class="card bg-base-100 shadow-xl mb-6">
          <div class="card-body">
            <h2 class="card-title">Members</h2>
            <.table id="users" rows={@users}>
              <:col :let={user} label="Name">{user.display_name}</:col>
              <:col :let={user} label="Email">{to_string(user.email)}</:col>
              <:col :let={user} label="Status">
                {if user.confirmed_at, do: "Confirmed", else: "Pending"}
              </:col>
            </.table>
          </div>
        </div>

        <div class="card bg-base-100 shadow-xl mb-6">
          <div class="card-body">
            <div class="flex justify-between items-center mb-4">
              <h2 class="card-title">Tags</h2>
              <.button phx-click={show_modal("tag-modal")}>
                <.heroicon name="hero-plus-circle" class="size-4 mr-2" /> Add Tag
              </.button>
            </div>
            <.tag_list tags={@tags} />
          </div>
        </div>

        <.modal id="invite-modal" title="Invite Partner">
          <.form for={@form} phx-submit="invite_partner" phx-change="validate_partner_email">
            <.input
              field={@form[:email]}
              type="email"
              label="Partner's Email"
              placeholder="partner@example.com"
              required
            />

            <div class="flex justify-end gap-3 mt-6">
              <.button type="button" aria-label="Close" phx-click={hide_modal("invite-modal")}>
                Cancel
              </.button>
              <.button type="submit" variant="primary">
                Send Invitation
              </.button>
            </div>
          </.form>
        </.modal>

        <.tag_modal tag_form={@tag_form} />
      </div>
    </Layouts.app>
    """
  end

  # Function component for displaying the list of tags
  defp tag_list(assigns) do
    ~H"""
    <div class="space-y-2">
      <p :if={Enum.empty?(@tags)} class="text-neutral-content">No tags created yet.</p>
      <div
        :for={tag <- @tags}
        class="flex items-center justify-between p-2 rounded-lg hover:bg-base-200"
      >
        <div class="flex items-center">
          <span class="mr-2">
            <.heroicon :if={tag.icon} name={tag.icon} class="size-5" />
            <.heroicon :if={!tag.icon} name="hero-tag" class="size-5" />
          </span>
          <span style={"color: #{tag.color};"}>{tag.name}</span>
        </div>
        <%!-- Future: Add edit/delete buttons here --%>
      </div>
    </div>
    """
  end

  # Function component for the tag creation modal
  defp tag_modal(assigns) do
    ~H"""
    <.modal id="tag-modal" title="Add New Tag">
      <.form for={@tag_form} phx-submit="save_tag" phx-change="validate_tag" id="tag-form">
        <.input
          field={@tag_form[:name]}
          label="Tag Name"
          placeholder="e.g., Holiday, Important, Funny"
          required
        />
        <div class="hidden">
          <!-- for now these are hidden because icon and color are not used in the output -->
          <.input
            field={@tag_form[:icon]}
            label="Icon (Optional)"
            placeholder="e.g., hero-sparkles (see heroicons.com)"
            class="hidden"
          />
          <.input
            field={@tag_form[:color]}
            label="Color (Optional)"
            placeholder="e.g., #ff00ff or text-blue-500"
          />
        </div>

        <div class="flex justify-end gap-3 mt-6">
          <.button type="button" aria-label="Close" phx-click={hide_modal("tag-modal")}>
            Cancel
          </.button>
          <.button type="submit" variant="primary" phx-disable-with="Saving...">
            Save Tag
          </.button>
        </div>
      </.form>
    </.modal>
    """
  end
end
