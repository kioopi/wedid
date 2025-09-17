defmodule WedidWeb.User.SettingsLive do
  use WedidWeb, :live_view

  alias Wedid.Accounts

  on_mount {WedidWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, session, socket) do
    current_user = socket.assigns.current_user
    current_locale = Map.get(session, "locale", "en")

    profile_form = Accounts.form_to_update_user_profile(current_user, actor: current_user)
    change_password_form = Accounts.form_to_change_password(current_user, actor: current_user)

    {:ok,
     socket
     |> assign(:page_title, gettext("Settings"))
     |> assign(:profile_form, to_form(profile_form))
     |> assign(:change_password_form, to_form(change_password_form))
     |> assign(:current_locale, current_locale)}
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
         |> put_flash(:info, gettext("Profile updated successfully."))
         |> assign(
           :profile_form,
           to_form(Accounts.form_to_update_user_profile(user, actor: user))
         )}

      {:error, form} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to update profile."))
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
         |> put_flash(:info, gettext("Password updated successfully."))
         |> assign(
           :profile_form,
           to_form(Accounts.form_to_change_password(user, actor: user))
         )}

      {:error, form} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to update password."))
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
         |> put_flash(:info, gettext("Password reset link sent to your email."))}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           gettext("Failed to send password reset link: %{reason}", reason: reason)
         )}
    end
  end

  @impl true
  def handle_event("change_locale", %{"locale" => locale}, socket) do
    if WedidWeb.Locale.supported_locale?(locale) do
      # Set the locale in Gettext for this process (mainly for consistency)
      Gettext.put_locale(WedidWeb.Gettext, locale)

      # Update the socket state and trigger a page reload
      # Page reload is necessary because LiveView templates are compiled 
      # and don't re-evaluate gettext calls when locale changes mid-session
      {:noreply,
       socket
       |> assign(:current_locale, locale)
       |> assign(:page_title, gettext("Settings"))
       |> push_event("locale-changed", %{locale: locale, shouldReload: true})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("sync_locale", %{"locale" => locale}, socket) do
    if WedidWeb.Locale.supported_locale?(locale) do
      # Set the locale in Gettext for this process
      Gettext.put_locale(WedidWeb.Gettext, locale)

      # This is for silent sync (initial page load) - no reload needed
      # Just update the socket state, the session will be updated by SetLocale plug
      {:noreply,
       socket
       |> assign(:current_locale, locale)
       |> assign(:page_title, gettext("Settings"))
       |> push_event("locale-changed", %{locale: locale, shouldReload: false})}
    else
      {:noreply, socket}
    end
  end

  attr :theme, :string, required: true, doc: "name of the theme"
  attr :label, :string, required: true, doc: "name of the theme"

  defp theme_button(assigns) do
    ~H"""
    <li>
      <input
        type="radio"
        name="theme-dropdown"
        class="theme-controller btn btn-sm btn-block btn-ghost justify-start checked:btn-active checked:bg-primary"
        aria-label={@label}
        value={@theme}
        data-set-theme={@theme}
      />
    </li>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto p-6">
        <.header class="mb-8">
          {gettext("User Settings")}
        </.header>

        <.card title={gettext("Color theme")}>
          <p>{gettext("Select a color theme for the application.")}</p>

          <:actions>
            <.theme_switcher id="theme-switcher" />
          </:actions>
        </.card>

        <.card title={gettext("Language")}>
          <p>{gettext("Select your preferred language for the application.")}</p>

          <:actions>
            <.language_switcher
              id="language-switcher"
              current_locale={@current_locale}
              change_event="change_locale"
            />
          </:actions>
        </.card>

        <.card title={gettext("Profile information")}>
          <.profile_form form={@profile_form} />
        </.card>

        <.card title={gettext("Profile picture")}>
          <p class="mt-1 text-sm text-base-content/70">
           {gettext("Manage your profile picture at Gravatar.com")}
          </p>

          <:actions>
            <a href="https://gravatar.com" target="_blank" rel="noopener noreferrer" class="link link-primary">
              {gettext("Go to Gravatar.com")}
            </a>
          </:actions>
        </.card>

        <.card title={gettext("Change password")}>
          <.change_password_form form={@change_password_form} />
        </.card>

        <.card title={gettext("Reset password")}>
          <p class="mt-1 text-sm text-base-content/70">
            {gettext(
              "Use this to set your password after being invited to the application or if you have"
            )}
            {gettext("forgotten your password and signed-in with a magic link.")}
          </p>

          <:actions>
            <.button
              type="submit"
              variant="primary"
              phx-click="request_password_reset"
              phx-disable-with={gettext("Requesting...")}
            >
              {gettext("Request password reset link")}
            </.button>
          </:actions>
        </.card>
      </div>
    </Layouts.app>
    """
  end

  attr :id, :string, required: true, doc: "the dom id of the modal"

  def theme_switcher(assigns) do
    ~H"""
    <div class="dropdown " title="Change Theme" id={@id} phx-hook="ThemeSwitcher">
      <div tabindex="0" role="button" class="btn btn-primary">
        {gettext("Theme")}
        <svg
          width="12px"
          height="12px"
          class="h-2 w-2 fill-current opacity-60 inline-block"
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 2048 2048"
        >
          <path d="M1799 349l242 241-1017 1017L7 590l242-241 775 775 775-775z"></path>
        </svg>
      </div>
      <ul tabindex="0" class="dropdown-content z-[1] p-2 shadow-2xl bg-base-300 rounded-box w-52">
        <.theme_button theme="light" label="Default" />
        <.theme_button theme="dark" label="Dark" />
        <.theme_button theme="cupcake" label="Cupcake" />
        <.theme_button theme="bumblebee" label="Bumblebee" />
        <.theme_button theme="emerald" label="Emerald" />
        <.theme_button theme="corporate" label="Corporate" />
        <.theme_button theme="synthwave" label="Synthwave" />
        <.theme_button theme="retro" label="Retro" />
        <.theme_button theme="cyberpunk" label="Cyberpunk" />
        <.theme_button theme="valentine" label="Valentine" />
        <.theme_button theme="halloween" label="Halloween" />
        <.theme_button theme="garden" label="Garden" />
        <.theme_button theme="forest" label="Forest" />
        <.theme_button theme="aqua" label="Aqua" />
        <.theme_button theme="lofi" label="Lofi" />
        <.theme_button theme="pastel" label="Pastel" />
        <.theme_button theme="fantasy" label="Fantasy" />
        <.theme_button theme="wireframe" label="Wireframe" />
        <.theme_button theme="black" label="Black" />
        <.theme_button theme="luxury" label="Luxury" />
        <.theme_button theme="dracula" label="Dracula" />
        <.theme_button theme="cmyk" label="CMYK" />
        <.theme_button theme="autumn" label="Autumn" />
        <.theme_button theme="business" label="Business" />
        <.theme_button theme="acid" label="Acid" />
        <.theme_button theme="lemonade" label="Lemonade" />
        <.theme_button theme="night" label="Night" />
        <.theme_button theme="coffee" label="Coffee" />
        <.theme_button theme="winter" label="Winter" />
      </ul>
    </div>
    """
  end

  attr :title, :string, required: true, doc: "the title of the card"
  slot :inner_block, required: true, doc: "the content to render inside the card"
  slot :actions, required: false, doc: "optional actions to render in the card footer"

  def card(assigns) do
    ~H"""
    <div class="card card-border mb-6">
      <div class="card-body">
        <h2 class="card-title">{@title}</h2>
        {render_slot(@inner_block)}
        <div :if={@actions != []} class="card-actions mt-5 justify-end">
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end

  attr :form, :map, required: true, doc: "the form for updating user profile"

  def profile_form(assigns) do
    ~H"""
    <p class="text-sm text-base-content/70 mb-4">
      {gettext("Update your account's profile information.")}
    </p>

    <.form
      for={@form}
      phx-change="validate_profile"
      phx-submit="save_profile"
      class="profile-form space-y-4"
    >
      <.input
        field={@form[:name]}
        type="text"
        label={gettext("Name")}
        placeholder={gettext("Your name")}
      />
      <p class="mt-1 text-sm text-base-content/70">
        {gettext("This is how you will appear to others in the application.")}
      </p>

      <div class="flex justify-end">
        <.button type="submit" variant="primary" phx-disable-with={gettext("Saving...")}>
          {gettext("Save Changes")}
        </.button>
      </div>
    </.form>
    """
  end

  attr :form, :map, required: true, doc: "the form for changing a users password"

  def change_password_form(assigns) do
    ~H"""
    <p class="text-sm text-base-content/70 mb-4">
      {gettext("Change your password")}
    </p>

    <.form for={@form} phx-change="validate_password" phx-submit="save_password" class="space-y-4">
      <.input field={@form[:current_password]} type="password" label={gettext("Current password")} />
      <hr />
      <.input field={@form[:password]} type="password" label={gettext("New password")} />
      <.input
        field={@form[:password_confirmation]}
        type="password"
        label={gettext("New password confirmation")}
      />

      <div class="flex justify-end">
        <.button type="submit" variant="primary" phx-disable-with={gettext("Saving...")}>
          {gettext("Change password")}
        </.button>
      </div>
    </.form>
    """
  end
end
