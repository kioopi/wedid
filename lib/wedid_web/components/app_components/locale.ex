defmodule WedidWeb.AppComponents.Locale do
  @moduledoc """
  Provides UI components specific to the WeDid application.

  These components are designed to work with the existing CoreComponents
  and provide more specific UI elements for this relationship tracking app.
  """
  use Phoenix.Component
  use WedidWeb, :verified_routes
  use Gettext, backend: WedidWeb.Gettext
  alias WedidWeb.Locale

  @doc """
  Renders the language switcher dropdown used throughout the application.

  ## Examples

      <.switcher id="language-switcher" current_locale="en" />
  """
  attr :id, :string, default: nil, doc: "the DOM id of the language switcher"
  attr :current_locale, :string, default: nil, doc: "the locale currently selected"

  def switcher(assigns) do
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
              href="#"
              class={
                "btn btn-sm btn-block btn-ghost justify-start " <>
                  if(locale.code == @current_locale, do: "btn-active bg-primary", else: "")
              }
              onclick={"document.documentElement.setAttribute('lang', '#{locale.code}')"}
            >
              {locale.flag} {locale.name}
            </a>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
