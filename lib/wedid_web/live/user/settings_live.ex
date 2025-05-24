defmodule WedidWeb.User.SettingsLive do
  use WedidWeb, :live_view

  alias Wedid.Accounts

  on_mount {WedidWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    profile_form = Accounts.form_to_update_user_profile(current_user, actor: current_user)

    {:ok,
     socket
     |> assign(:page_title, "Settings")
     |> assign(:profile_form, to_form(profile_form))}
  end

  @impl true
  def handle_event("validate_profile", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.profile_form, params)
    {:noreply, assign(socket, :profile_form, form)}
  end

  @impl true
  def handle_event("save_profile", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.profile_form, params: params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully.")
         |> assign(
           :profile_form,
           to_form(Accounts.form_to_update_user_profile(user, actor: user))
         )}

      {:error, form} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update profile.")
         |> assign(:profile_form, form)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="container mx-auto p-6">
        <.header class="mb-8">
          User Settings
        </.header>

        <div class="card bg-base-100 shadow-xl mb-6">
          <div class="card-body">
            <h2 class="card-title">Profile Information</h2>
            <p class="text-sm text-base-content/70 mb-4">
              Update your account's profile information.
            </p>

            <.form
              for={@profile_form}
              phx-change="validate_profile"
              phx-submit="save_profile"
              class="space-y-4"
            >
              <.input field={@profile_form[:name]} type="text" label="Name" placeholder="Your name" />
              <p class="mt-1 text-sm text-base-content/70">
                This is how you will appear to others in the application.
              </p>

              <div class="flex justify-end">
                <.button type="submit" variant="primary">
                  Save Changes
                </.button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
