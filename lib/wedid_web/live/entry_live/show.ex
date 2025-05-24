defmodule WedidWeb.EntryLive.Show do
  use WedidWeb, :live_view

  on_mount {WedidWeb.LiveUserAuth, :live_user_required}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="min-h-screen bg-gradient-to-b from-base-100 to-base-200">
        <div class="container mx-auto px-4 py-8 max-w-4xl">
          <.header>
            <div class="flex items-center gap-2">
              <.heroicon name="hero-book-open" class="size-6 text-primary" />
              <span>Entry Details</span>
            </div>
            <:subtitle>
              Viewing entry from {Calendar.strftime(@entry.created_at, "%b %d, %Y")}
            </:subtitle>

            <:actions>
              <.button navigate={~p"/entries"} class="btn btn-ghost">
                <.heroicon name="hero-arrow-left" class="size-4 mr-1" /> Back to Entries
              </.button>
            </:actions>
          </.header>

          <div class="max-w-2xl mx-auto mt-6">
            <.journal_entry entry={@entry} current_user={@current_user} />

            <div class="card bg-base-100 shadow-md mt-6 p-4">
              <h3 class="text-sm font-semibold mb-2">Additional Information</h3>
              <div class="text-xs text-base-content/70">
                <div class="flex justify-between mb-1">
                  <span>Entry ID:</span>
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
       Ash.get!(Wedid.Diaries.Entry, id, actor: socket.assigns.current_user, load: [:user])
     )
     |> assign(:current_user, socket.assigns.current_user)}
  end

  defp page_title(:show), do: "Show Entry"
  defp page_title(:edit), do: "Edit Entry"
end
