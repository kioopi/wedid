defmodule WedidWeb.User.SettingsLive do
  use WedidWeb, :live_view

  alias Wedid.Accounts

  on_mount {WedidWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    profile_form = Accounts.form_to_update_user_profile(current_user, actor: current_user)
    change_password_form = Accounts.form_to_change_password(current_user, actor: current_user)

    {:ok,
     socket
     |> assign(:page_title, "Settings")
     |> assign(:profile_form, to_form(profile_form))
     |> assign(:change_password_form, to_form(change_password_form))}
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
  def handle_event("validate_password", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.profile_form, params)
    {:noreply, assign(socket, :change_password_form, form)}
  end

  @impl true
  def handle_event("save_password", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.change_password_form, params: params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password updated successfully.")
         |> assign(
           :profile_form,
           to_form(Accounts.form_to_change_password(user, actor: user))
         )}

      {:error, form} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update profile.")
         |> assign(:change_password_form, form)}
    end
  end

  @impl true
  def handle_event("request_password_reset", _params, socket) do
    user = socket.assigns.current_user

    case Wedid.Accounts.User.request_password_reset(to_string(user.email), actor: user) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset link sent to your email.")}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to send password reset link: #{reason}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto p-6">
        <.header class="mb-8">
          User Settings
        </.header>

        <.card title="Color theme">
          <WedidWeb.Layouts.theme_toggle />
        </.card>

        <.card title="Profile information">
          <.profile_form form={@profile_form} />
        </.card>

        <.card title="Change password">
          <.change_password_form form={@change_password_form} />
        </.card>

        <.card title="Reset password">
          <p class="mt-1 text-sm text-base-content/70">
            Use this to set your password after being invited to the application or if you have
            forgotten your password and signed-in with a magic link.
          </p>
          <.button
            type="submit"
            variant="primary"
            phx-click="request_password_reset"
            phx-disable-with="Requesting..."
          >
            Request password reset link
          </.button>
        </.card>
      </div>
    </Layouts.app>
    """
  end

  attr :title, :string, required: true, doc: "the title of the card"
  slot :inner_block, required: true, doc: "the content to render inside the card"

  def card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl mb-6">
      <div class="card-body">
        <h2 class="card-title">{@title}</h2>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :form, :map, required: true, doc: "the form for updating user profile"

  def profile_form(assigns) do
    ~H"""
    <p class="text-sm text-base-content/70 mb-4">
      Update your account's profile information.
    </p>

    <.form
      for={@form}
      phx-change="validate_profile"
      phx-submit="save_profile"
      class="profile-form space-y-4"
    >
      <.input field={@form[:name]} type="text" label="Name" placeholder="Your name" />
      <p class="mt-1 text-sm text-base-content/70">
        This is how you will appear to others in the application.
      </p>

      <div class="flex justify-end">
        <.button type="submit" variant="primary" phx-disable-with="Saving...">
          Save Changes
        </.button>
      </div>
    </.form>
    """
  end

  attr :form, :map, required: true, doc: "the form for changing a users password"

  def change_password_form(assigns) do
    ~H"""
    <p class="text-sm text-base-content/70 mb-4">
      Change your password
    </p>

    <.form for={@form} phx-change="validate_password" phx-submit="save_password" class="space-y-4">
      <.input field={@form[:current_password]} type="password" label="Current password" />
      <hr />
      <.input field={@form[:password]} type="password" label="New password" />
      <.input field={@form[:password_confirmation]} type="password" label="New password confirmation" />

      <div class="flex justify-end">
        <.button type="submit" variant="primary" phx-disable-with="Saving...">
          Change password
        </.button>
      </div>
    </.form>
    """
  end
end
