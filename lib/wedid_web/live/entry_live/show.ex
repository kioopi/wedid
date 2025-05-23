defmodule WedidWeb.EntryLive.Show do
  use WedidWeb, :live_view

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
              <.button variant="primary" navigate={~p"/entries/#{@entry}/edit?return_to=show"}>
                <.heroicon name="hero-pencil-square" class="size-4 mr-1" /> Edit Entry
              </.button>
            </:actions>
          </.header>

          <div class="card bg-base-100 shadow-lg mt-6">
            <div class="card-body">
              <h2 class="card-title font-bold text-primary">
                <%= if @entry.user && @entry.user.email do %>
                  Entry by {Ash.CiString.value(@entry.user.email)}
                <% else %>
                  Entry
                <% end %>
              </h2>

              <div class="divider"></div>

              <.list>
                <:item title="Id"><span class="badge badge-neutral">{@entry.id}</span></:item>
                <:item title="Content">
                  <div class="bg-base-200 p-4 rounded-lg mt-2">
                    {@entry.content}
                  </div>
                </:item>
                <:item title="Created at">
                  <span class="font-mono text-sm">
                    {Calendar.strftime(@entry.created_at, "%b %d, %Y at %I:%M %p")}
                  </span>
                </:item>
              </.list>
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
     )}
  end

  defp page_title(:show), do: "Show Entry"
  defp page_title(:edit), do: "Edit Entry"
end
