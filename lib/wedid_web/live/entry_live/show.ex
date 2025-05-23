defmodule WedidWeb.EntryLive.Show do
  use WedidWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Entry {@entry.id}
        <:subtitle>This is a entry record from your database.</:subtitle>

        <:actions>
          <.button navigate={~p"/entries"}>
            <.heroicon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/entries/#{@entry}/edit?return_to=show"}>
            <.heroicon name="hero-pencil-square" /> Edit Entry
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Id">{@entry.id}</:item>

        <:item title="Content">{@entry.content}</:item>

        <:item title="Created at">{@entry.created_at}</:item>
      </.list>
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
     |> assign(:entry, Ash.get!(Wedid.Diaries.Entry, id, actor: socket.assigns.current_user))}
  end

  defp page_title(:show), do: "Show Entry"
  defp page_title(:edit), do: "Edit Entry"
end
