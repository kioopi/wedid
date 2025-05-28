defmodule WedidWeb.Couple.CoupleLive do
  use WedidWeb, :live_view
  import WedidWeb.CoreComponents

  on_mount {WedidWeb.LiveUserAuth, :live_user_required}

  alias Wedid.Accounts

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok, current_user} =
      Ash.load(current_user, [couple: [:tags, users: [:display_name]]], actor: current_user) # Corrected order

    form = Accounts.form_to_invite_user(actor: current_user)
    tag_form = AshPhoenix.Form.for_create(Wedid.Diaries.Tag, :create, as: "new_tag", actor: socket.assigns.current_user)

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
  def handle_event("validate_tag", %{"new_tag" => tag_params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.tag_form, tag_params)
    {:noreply, assign(socket, tag_form: form)}
  end

  @impl true
  def handle_event("save_tag", %{"new_tag" => tag_params}, socket) do
    current_user = socket.assigns.current_user
    # The tag form should automatically set the couple_id via a change in the Tag resource's create action.
    # If not, it would need to be added here:
    # params = Map.put(tag_params, "couple_id", current_user.couple_id)

    case AshPhoenix.Form.submit(socket.assigns.tag_form, params: tag_params, actor: current_user) do
      {:ok, new_tag} ->
        # Reload couple with tags to get the new list
        {:ok, reloaded_couple} = Wedid.Accounts.Couple
        |> Ash.get!(current_user.couple_id, actor: current_user)
        |> Ash.load!([:tags], actor: current_user)

        new_tag_form = AshPhoenix.Form.for_create(Wedid.Diaries.Tag, :create, as: "new_tag", actor: current_user)

        socket =
          socket
          |> assign(tags: reloaded_couple.tags)
          |> assign(tag_form: to_form(new_tag_form))
          |> put_flash(:info, "Tag '#{new_tag.name}' created successfully!")
          |> push_event("hideModal", %{id: "tag-modal"}) # Assumes modal ID will be "tag-modal"

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
      <if {@tags == []}>
        <p class="text-neutral-content">No tags created yet.</p>
      </if>
      <for tag <- @tags>
        <div class="flex items-center justify-between p-2 rounded-lg hover:bg-base-200">
          <div class="flex items-center">
            <span class="mr-2">
              <if {tag.icon && String.trim(tag.icon) != ""}>
                <.heroicon name={tag.icon} class="size-5" />
              <else>
                <.heroicon name="hero-tag" class="size-5" />
              </else>
              </if>
            </span>
            <span style={"color: #{tag.color};"}>{tag.name}</span>
          </div>
          <%!-- Future: Add edit/delete buttons here --%>
        </div>
      </for>
    </div>
    """
  end

  # Function component for the tag creation modal
  defp tag_modal(assigns) do
    ~H"""
    <.modal id="tag-modal" title="Add New Tag">
      <.form for={@tag_form} phx-submit="save_tag" phx-change="validate_tag" id="tag-form">
        <.input field={@tag_form[:name]} label="Tag Name" placeholder="e.g., Holiday, Important, Funny" required />
        <.input field={@tag_form[:icon]} label="Icon (Optional)" placeholder="e.g., hero-sparkles (see heroicons.com)" />
        <.input field={@tag_form[:color]} label="Color (Optional)" placeholder="e.g., #ff00ff or text-blue-500" />

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
