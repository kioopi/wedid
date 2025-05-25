defmodule WedidWeb.Couple.CoupleLive do
  use WedidWeb, :live_view
  import WedidWeb.CoreComponents

  on_mount {WedidWeb.LiveUserAuth, :live_user_required}

  alias Wedid.Accounts

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok, current_user} =
      Ash.load(current_user, [couple: [users: [:display_name]]], actor: current_user)

    form = Accounts.form_to_invite_user(actor: current_user)

    if current_user.couple_id do
      {:ok,
       socket
       |> assign(:couple, current_user.couple)
       |> assign(:users, current_user.couple.users)
       |> assign(:form, to_form(form))}
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
      </div>
    </Layouts.app>
    """
  end
end
