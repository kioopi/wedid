defmodule WedidWeb.Couple.CoupleLive do
  use WedidWeb, :live_view
  import WedidWeb.CoreComponents

  on_mount {WedidWeb.LiveUserAuth, :live_user_required}

  alias Wedid.Accounts

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok, current_user} = Ash.load(current_user, [couple: :users], actor: current_user)

    form = Accounts.form_to_invite_user(actor: current_user)

    if current_user.couple_id do
      {:ok,
       socket
       |> assign(:couple, current_user.couple)
       |> assign(:users, current_user.couple.users)
       |> assign(:show_modal, false)
       |> assign(:form, to_form(form))}
    else
      {:ok, socket |> put_flash(:error, "You need to be part of a couple") |> redirect(to: "/")}
    end
  end

  @impl true
  def handle_event("open_invite_modal", _, socket) do
    {:noreply, assign(socket, :show_modal, true)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  @impl true
  def handle_event("invite_partner", %{"form" => form_data}, socket) do
    current_user = socket.assigns.current_user
    form_data = Map.put(form_data, "couple_id", current_user.couple_id)

    case AshPhoenix.Form.submit(socket.assigns.form, params: form_data) do
      {:ok, _invited_user} ->
        # Fixme: new user shoud just be appended assigns.users
        {:ok, current_user} = Ash.load(current_user, [couple: :users], actor: current_user)
        users = current_user.couple.users

        {:noreply,
         socket
         |> assign(:users, users)
         |> assign(:show_modal, false)
         |> put_flash(:info, "Partner invitation sent successfully!")}

      {:error, form} ->
        IO.inspect(form, label: "Form error")

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
    <Layouts.app flash={@flash}>
      <div class="container mx-auto p-6">
        <.header>
          Your Couple: {@couple.name}
          <:actions>
            <.button phx-click="open_invite_modal">
              <.heroicon name="hero-user-plus" class="size-4 mr-2" /> Invite Partner
            </.button>
          </:actions>
        </.header>

        <div class="card bg-base-100 shadow-xl mb-6">
          <div class="card-body">
            <h2 class="card-title">Members</h2>
            <.table id="users" rows={@users}>
              <:col :let={user} label="Email">{to_string(user.email)}</:col>
              <:col :let={user} label="Status">
                {if user.confirmed_at, do: "Confirmed", else: "Pending"}
              </:col>
            </.table>
          </div>
        </div>

        <%= if @show_modal do %>
          <div
            id="invite-modal"
            class="fixed inset-0 z-50 flex items-center justify-center"
            phx-window-keydown="close_modal"
            phx-key="escape"
          >
            <div class="fixed inset-0 bg-base-300 opacity-80" phx-click="close_modal"></div>
            <div class="relative z-10 w-full max-w-md p-6 mx-auto bg-base-100 rounded-lg shadow-lg">
              <div class="flex items-center justify-between mb-4">
                <h2 class="text-xl font-semibold">Invite Partner</h2>
                <button
                  type="button"
                  class="text-base-content/70 hover:text-base-content"
                  aria-label="Close"
                  phx-click="close_modal"
                >
                  <.heroicon name="hero-x-mark" class="size-5" />
                </button>
              </div>

              <.form for={@form} phx-submit="invite_partner" phx-change="validate_partner_email">
                <.input
                  field={@form[:email]}
                  type="email"
                  label="Partner's Email"
                  placeholder="partner@example.com"
                  required
                />

                <div class="flex justify-end gap-3 mt-6">
                  <.button type="button" phx-click="close_modal">
                    Cancel
                  </.button>
                  <.button type="submit" variant="primary">
                    Send Invitation
                  </.button>
                </div>
              </.form>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
