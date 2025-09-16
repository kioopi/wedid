defmodule WedidWeb.AppComponents do
  @moduledoc """
  Provides UI components specific to the WeDid application.

  These components are designed to work with the existing CoreComponents
  and provide more specific UI elements for this relationship tracking app.
  """
  use Phoenix.Component
  use WedidWeb, :verified_routes
  use Gettext, backend: WedidWeb.Gettext
  alias WedidWeb.CoreComponents, as: Core
  alias Phoenix.LiveView.JS
  alias WedidWeb.Locale

  @doc """
  Renders a single entry in the journal.

      <.journal_entry entry={entry} show_links={false} />
  """

  attr :entry, :map, required: true, doc: "the entry data"
  attr :id, :any, default: nil, doc: "the id for phx-update"

  # Renders a journal entry card with tag display and user attribution.
  #
  # Displays a diary entry in a card format with the following elements:
  # - Tag name (if entry has tags) displayed prominently at the top
  # - Entry content in the main body
  # - Creation date and author attribution at the bottom
  #
  # ## Examples
  #     # Entry with tags
  #     <.journal_entry entry={%Entry{
  #       content: "Great day!",
  #       tags: [%Tag{name: "Holiday"}],
  #       user: %User{display_name: "Alice"}
  #     }} />
  #
  #     # Entry without tags
  #     <.journal_entry entry={%Entry{
  #       content: "Regular day",
  #       tags: [],
  #       user: %User{display_name: "Bob"}
  #     }} />
  #
  def journal_entry(assigns) do
    ~H"""
    <div class="card bg-base-200 shadow-md p-4">
      <div
        :if={is_list(@entry.tags) && length(@entry.tags) > 0}
        class="py-2 text-m bold w-full flex items-center gap-2"
      >
        <span :if={hd(@entry.tags).icon} class="text-lg">{hd(@entry.tags).icon}</span>
        <span>{hd(@entry.tags).name}</span>
      </div>
      <div class="py-2 text-lg w-full">
        {@entry.content}
      </div>

      <div class="flex flex-row justify-between items-end mt-2">
        <div class="mb-1 text-sm text-base-content/70">
          {Calendar.strftime(@entry.created_at, "%b %d, %Y")}
        </div>
        <div class="text-sm font-semibold text-base-content/80">
          <span class="text-secondary">{@entry.user.display_name}</span>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the navigation bar with site branding and user authentication.

  ## Examples

      <.navbar current_user={@current_user} />
  """
  attr :current_user, :map, default: nil, doc: "the current user if signed in"
  attr :current_locale, :string, default: nil, doc: "the currently active locale"

  def navbar(assigns) do
    assigns =
      assign_new(assigns, :current_locale, fn -> Locale.current_locale() end)

    ~H"""
    <div class="navbar bg-primary text-primary-content shadow-md">
      <div class="navbar-start">
        <!-- Mobile dropdown -->
        <div class="dropdown lg:hidden">
          <div tabindex="0" role="button" class="btn btn-ghost">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 6h16M4 12h8m-8 6h16"
              />
            </svg>
          </div>
          <ul
            tabindex="0"
            class="menu menu-sm dropdown-content bg-primary rounded-box z-[1] mt-3 w-52 p-2 shadow"
          >
            <.nav_items current_user={@current_user} />
          </ul>
        </div>
        <!-- Brand logo -->
        <a href="/" class="text-xl font-bold btn btn-ghost normal-case">
          <span class="text-2xl">❤️</span> WeDid
        </a>
      </div>
      
    <!-- Desktop center menu -->
      <div class="navbar-center hidden lg:flex">
        <ul class="menu menu-horizontal px-1">
          <.nav_items current_user={@current_user} />
        </ul>
      </div>

      <div class="navbar-end">
        <%= if @current_user do %>
          <Core.user_menu current_user={@current_user} />
        <% else %>
          <div class="flex items-center gap-2">
            <.language_switcher
              id="navbar-language-switcher"
              current_locale={@current_locale}
            />
            <.auth_buttons />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders navigation items

  ## Examples

      <.nav_items />

  """
  def nav_items(assigns) do
    ~H"""
    <%= if @current_user do %>
      <li><a href="/entries" class="hover:bg-primary-focus">{gettext("Entries")}</a></li>
      <li><a href="/couple" class="hover:bg-primary-focus">{gettext("Couple")}</a></li>
    <% end %>
    """
  end

  @doc """
  Renders authentication buttons for non-authenticated users.

  ## Examples

      <.auth_buttons />

  """
  def auth_buttons(assigns) do
    ~H"""
    <a href="/sign-in" class="btn btn-ghost btn-sm">
      {gettext("Sign in")}
    </a>
    <a href="/register" class="btn btn-secondary btn-sm ml-2">
      {gettext("Sign up")}
    </a>
    """
  end

  @doc """
  Renders the language switcher dropdown used throughout the application.

  ## Examples

      <.language_switcher id="language-switcher" current_locale="en" change_event="change_locale" />
  """
  attr :id, :string, default: nil, doc: "the DOM id of the language switcher"
  attr :current_locale, :string, default: nil, doc: "the locale currently selected"
  attr :change_event, :string, default: nil, doc: "optional phx-click event for LiveView integration"

  def language_switcher(assigns) do
    assigns = assign_new(assigns, :current_locale, fn -> Locale.current_locale() end)

    assigns =
      assigns
      |> assign(:current_locale_flag, Locale.locale_flag(assigns.current_locale))
      |> assign(:current_locale_name, Locale.locale_name(assigns.current_locale))

    ~H"""
    <div
      class="dropdown"
      title={gettext("Change Language")}
      id={@id}
      phx-hook="LocaleSwitcher"
      data-current-locale={@current_locale}
    >
      <div tabindex="0" role="button" class="btn btn-primary">
        {@current_locale_flag}
        {@current_locale_name}
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
        <%= for locale <- Locale.supported_locales() do %>
          <li>
            <a
              href={"?locale=#{locale.code}"}
              class={
                "btn btn-sm btn-block btn-ghost justify-start " <>
                  if(locale.code == @current_locale, do: "btn-active bg-primary", else: "")
              }
              data-locale-link
              data-locale={locale.code}
              phx-click={@change_event}
              phx-value-locale={locale.code}
            >
              {locale.flag} {locale.name}
            </a>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  def hide_modal(id) do
    JS.dispatch("hideModal", to: "##{id}")
  end

  def show_modal(id) do
    JS.dispatch("showModal", to: "##{id}")
  end

  @doc """
  Renders a modal dialog with a close button.

  This component relies on a JavaScript hook in `assets/js/modal.js` to handle
  opening and closing behaviors. Use the `show_modal/1` and `hide_modal/1`
  functions to control the modal visibility.

  ## Examples

      <.modal id="my-modal" title="Important Information">
        <div>Modal content goes here</div>
        <.button phx-click={hide_modal("my-modal")}>Close</.button>
      </.modal>

      <.button phx-click={show_modal("my-modal")}>Open Modal</.button>
  """
  attr :id, :string, required: true, doc: "the dom id of the modal"
  attr :title, :string, required: false, default: nil, doc: "the title of the modal"
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <dialog id={@id} class="modal" phx-hook="Modal">
      <div class="modal-box">
        <div class="flex items-center justify-between mb-4">
          <h2 :if={@title} class="text-xl font-semibold">{@title}</h2>
          <button
            type="button"
            class="text-base-content/70 hover:text-base-content"
            aria-label={gettext("Close")}
            phx-click={hide_modal(@id)}
          >
            <Core.heroicon name="hero-x-mark" class="size-5" />
          </button>
        </div>
        <div class="modal-action">
          {render_slot(@inner_block)}
        </div>
      </div>
    </dialog>
    """
  end

  @doc """
  Renders a card for a couple with partner.

  ## Examples

      <.couple_card couple={@couple} entries={@entries} entries_by_day={@entries_by_day} />
  """
  attr :couple, :map, required: true, doc: "the couple data"
  attr :entries, :list, required: true, doc: "list of all entries"
  attr :entries_by_day, :map, required: true, doc: "entries grouped by day"

  def couple_card(assigns) do
    ~H"""
    <div class="card bg-base-100 border-t-4 border-primary">
      <div class="card-body">
        <div class="flex items-center justify-center gap-3 mb-6">
          <.icon name="heart" />
          <h2 class="card-title text-3xl font-bold text-center">{@couple.name}</h2>
        </div>

        <div class="divider">
          <div class="badge badge-primary badge-lg gap-2">
            <.icon name="calendar" class="w-5 h-5" /> {gettext("Your shared moments")}
          </div>
        </div>

        <%= if Enum.empty?(@entries) do %>
          <.empty_entries_placeholder />
        <% else %>
          <%= for entry <- @entries do %>
            <.journal_entry entry={entry} />
          <% end %>

          <div class="mt-8 text-center">
            <.add_moment_button />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders a placeholder for when there are no entries.

  ## Examples

      <.empty_entries_placeholder />
  """
  def empty_entries_placeholder(assigns) do
    ~H"""
    <div class="text-center py-12 bg-base-200 rounded-xl">
      <.icon name="edit" class="w-16 h-16 mx-auto text-primary mb-4 opacity-60" />
      <h3 class="text-2xl font-medium mb-4">{gettext("No moments recorded yet")}</h3>
      <p class="mb-6 text-base-content/70 max-w-md mx-auto">
        {gettext(
          "This is where you'll see all the special moments you and your partner share. Start your journey of gratitude today!"
        )}
      </p>
      <.add_moment_button />
    </div>
    """
  end

  @doc """
  Renders a button to add a new moment.

  ## Examples

      <.add_moment_button />
  """
  attr :class, :string, default: "btn btn-primary btn-lg gap-2"

  def add_moment_button(assigns) do
    ~H"""
    <a href={~p"/entries"} class={@class}>
      <.icon name="plus" /> {gettext("See all moments")}
    </a>
    """
  end

  @doc """
  Renders the section for when a user has a couple but no partner yet.

  ## Examples

      <.waiting_for_partner />
  """
  def waiting_for_partner(assigns) do
    ~H"""
    <div class="hero bg-gradient-to-br from-primary/10 to-secondary/10 rounded-box">
      <div class="hero-content text-center py-16">
        <div class="max-w-md">
          <div class="mask mask-heart mb-8 bg-primary/20 p-8 mx-auto w-32 h-32 flex items-center justify-center">
            <.icon name="users" class="w-16 h-16 text-primary" />
          </div>
          <h1 class="text-4xl font-bold mb-4">{gettext("Almost there!")}</h1>
          <p class="mb-8 text-xl">
            {gettext("But your partner hasn't joined yet.")}
          </p>
          <.partner_invite_card />
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the invitation card for partner.

  ## Examples

      <.partner_invite_card />
  """
  def partner_invite_card(assigns) do
    ~H"""
    <div class="card bg-base-100 border-y-4 border-primary">
      <div class="card-body">
        <div class="flex items-center gap-2">
          <.icon name="mail" class="w-6 h-6 text-primary" />
          <h2 class="card-title">{gettext("Invite your partner")}</h2>
        </div>
        <p class="mb-4">
          {gettext(
            "Share your journey of gratitude and connection together. Your partner will be able to join with a special invitation link."
          )}
        </p>
        <div class="card-actions justify-center">
          <Core.button variant="large" class="btn btn-primary btn-lg gap-2">
            <.icon name="send" class="w-6 h-6" /> {gettext("Send invite")}
          </Core.button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the welcome section for users without a couple.

  ## Examples

      <.welcome_section />
  """
  def welcome_section(assigns) do
    ~H"""
    <div class="hero bg-gradient-to-br from-primary/10 to-secondary/10 rounded-box">
      <div class="hero-content text-center py-16">
        <div class="max-w-lg">
          <div class="mask mask-heart mb-8 bg-primary/20 p-8 mx-auto w-32 h-32 flex items-center justify-center">
            <.icon name="heart" class="w-16 h-16 text-primary" />
          </div>
          <h1 class="text-5xl font-bold mb-4">{gettext("Welcome to WeDid!")}</h1>
          <p class="mb-8 text-xl max-w-md mx-auto">
            {gettext(
              "Let's set up your couple profile to start recording beautiful moments together."
            )}
          </p>
          <button class="btn btn-primary btn-lg gap-2">
            <.icon name="plus" class="w-6 h-6" /> {gettext("Create your couple")}
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the landing page hero section for non-authenticated users.

  ## Examples

      <.landing_hero />
  """
  def landing_hero(assigns) do
    ~H"""
    <div class="hero min-h-[85vh] bg-gradient-to-br from-primary/10 to-secondary/10">
      <div class="hero-content flex-col lg:flex-row-reverse gap-12">
        <img
          src="https://picsum.photos/600/400"
          class="max-w-sm rounded-lg shadow-2xl border-8 border-white rotate-3"
          alt="Couple sharing a moment"
        />
        <div class="max-w-2xl">
          <div class="flex items-center gap-3 mb-4">
            <span class="text-4xl">❤️</span>
            <h1 class="text-6xl font-bold bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
              WeDid
            </h1>
          </div>
          <p class="py-3 text-3xl font-light">
            {gettext("Celebrate your shared journey—one positive moment at a time.")}
          </p>
          <div class="py-4 prose prose-lg">
            <p>
              {gettext(
                "A success & gratitude diary for two. Every day, both partners can log small or big things that went well: a kind word, a shared laugh, a problem solved, or a moment of connection."
              )}
            </p>
            <p>{gettext("Build resilience together by focusing on what brings you joy.")}</p>
          </div>
          <div class="mt-8 flex gap-4">
            <a href="/register" class="btn btn-primary btn-lg gap-2">
              <.icon name="plus" class="w-6 h-6" /> {gettext("Get Started")}
            </a>
            <a href="/sign-in" class="btn btn-outline btn-lg">{gettext("Sign In")}</a>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the features section for the landing page.

  ## Examples

      <.features_section />
  """
  def features_section(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-24">
      <h2 class="text-4xl font-bold text-center mb-4">{gettext("Why WeDid Works")}</h2>
      <p class="text-center max-w-xl mx-auto mb-16 text-lg opacity-70">
        {gettext(
          "Based on relationship research and designed for couples who want to build a stronger connection"
        )}
      </p>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
        <.feature_card
          title={gettext("Positive Focus")}
          color="primary"
          icon="smile"
          description={
            gettext(
              "Relationships thrive on connection, recognition, and positivity. WeDid helps you capture what matters most in your relationship."
            )
          }
        />

        <.feature_card
          title={gettext("Shared Memory")}
          color="secondary"
          icon="book"
          description={
            gettext(
              "Build a collective journal of what works—a source of strength, joy, and perspective during both good and challenging times."
            )
          }
        />

        <.feature_card
          title={gettext("Research-Backed")}
          color="accent"
          icon="shield"
          description={
            gettext(
              "Inspired by principles from Positive Psychology, Gottman Method, Narrative Therapy, and Emotionally Focused Therapy."
            )
          }
        />
      </div>

      <div class="text-center mt-16">
        <a href="/register" class="btn btn-lg btn-primary">
          {gettext("Start Your Journey Together")}
        </a>
      </div>
    </div>
    """
  end

  @doc """
  Renders a feature card for the landing page.

  ## Examples

      <.feature_card
        title="Positive Focus"
        color="primary"
        icon="smile"
        description="Relationships thrive on connection, recognition, and positivity."
      />
  """
  attr :title, :string, required: true, doc: "the title of the feature"
  attr :color, :string, required: true, doc: "the color theme (primary, secondary, accent)"
  attr :icon, :string, required: true, doc: "the icon name"
  attr :description, :string, required: true, doc: "the feature description"

  def feature_card(assigns) do
    ~H"""
    <div class={"card bg-base-100 shadow-xl hover:shadow-2xl transition-all duration-300 border-t-4 border-#{@color}"}>
      <div class="card-body items-center text-center">
        <div class={"w-16 h-16 rounded-full bg-#{@color}/10 flex items-center justify-center mb-4"}>
          <.icon name={@icon} class={"w-8 h-8 text-#{@color}"} />
        </div>
        <h3 class="card-title text-2xl mb-2">{@title}</h3>
        <p class="text-base-content/70">
          {@description}
        </p>
      </div>
    </div>
    """
  end

  @doc """
  Renders common SVG icons used throughout the application.

  ## Examples

      <.icon name="heart" />
      <.icon name="calendar" class="w-5 h-5" />
  """
  attr :name, :string, required: true, doc: "the name of the icon"
  attr :class, :string, default: "w-8 h-8 text-primary", doc: "the CSS classes"

  def icon(%{name: "heart"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
      />
    </svg>
    """
  end

  def icon(%{name: "calendar"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
      />
    </svg>
    """
  end

  def icon(%{name: "edit"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
      />
    </svg>
    """
  end

  def icon(%{name: "plus"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M12 6v6m0 0v6m0-6h6m-6 0H6"
      />
    </svg>
    """
  end

  def icon(%{name: "users"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
      />
    </svg>
    """
  end

  def icon(%{name: "mail"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
      />
    </svg>
    """
  end

  def icon(%{name: "send"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"
      />
    </svg>
    """
  end

  def icon(%{name: "smile"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
      />
    </svg>
    """
  end

  def icon(%{name: "book"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
      />
    </svg>
    """
  end

  def icon(%{name: "shield"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
      />
    </svg>
    """
  end
end
