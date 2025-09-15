defmodule WedidWeb.EntryLive.Show do
  use WedidWeb, :live_view

  on_mount {WedidWeb.LiveUserAuth, :live_user_required}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="min-h-screen bg-gradient-to-b from-base-100 to-base-200">
        <div class="container mx-auto px-4 py-8 max-w-4xl">
          <.header>
            <div class="flex items-center gap-2">
              <.heroicon name="hero-book-open" class="size-6 text-primary" />
              <span>{gettext("Entry Details")}</span>
            </div>
            <:subtitle>
              {gettext("Viewing entry from %{date}", date: Calendar.strftime(@entry.created_at, "%b %d, %Y"))}
            </:subtitle>

            <:actions>
              <.button navigate={~p"/entries"} class="btn btn-ghost">
                <.heroicon name="hero-arrow-left" class="size-4 mr-1" /> {gettext("Back to Entries")}
              </.button>
            </:actions>
          </.header>

          <div class="max-w-2xl mx-auto mt-6">
            <.journal_entry entry={@entry} />

            <div class="card bg-base-100 shadow-md mt-6 p-4">
              <h3 class="text-sm font-semibold mb-2">{gettext("Actions")}</h3>
              <div class="flex gap-1">
                <.link navigate={~p"/entries/#{@entry}/edit"} class="btn btn-xs btn-ghost">
                  <.heroicon name="hero-pencil-square" class="size-4" /> {gettext("Edit")}
                </.link>
                <.link
                  phx-click={JS.push("delete", value: %{id: @entry.id})}
                  data-confirm={gettext("Are you sure you want to delete this entry?")}
                  class="btn btn-xs btn-ghost text-error self-end"
                >
                  <.heroicon name="hero-trash" class="size-4" /> {gettext("Delete")}
                </.link>
              </div>
            </div>

            <div class="card bg-base-100 shadow-md mt-6 p-4">
              <h3 class="text-sm font-semibold mb-2">{gettext("Additional Information")}</h3>
              <div class="text-xs text-base-content/70">
                <div class="flex justify-between mb-1">
                  <span>{gettext("Entry ID:")}</span>
                  <span class="badge badge-sm badge-neutral">{@entry.id}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(
       :entry,
       Ash.get!(Wedid.Diaries.Entry, id,
         actor: socket.assigns.current_user,
         load: [:tags, user: [:display_name]]
       )
     )
     |> assign(:current_user, socket.assigns.current_user)}
  end

  defp page_title(:show), do: gettext("Show Entry")
  defp page_title(:edit), do: gettext("Edit Entry")
end
