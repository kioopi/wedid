defmodule WedidWeb.EntryLive.Index do
  use WedidWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    entries =
      Wedid.Diaries.list_entries!(actor: socket.assigns.current_user)

    {:ok,
     socket
     |> stream(:entries, entries)
     |> assign_new(:current_user, fn -> nil end)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Entry")
    |> assign(:entry, Ash.get!(Wedid.Diaries.Entry, id, actor: socket.assigns.current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Entry")
    |> assign(:entry, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Entries")
    |> assign(:entry, nil)
  end

  @impl true
  def handle_info({WedidWeb.EntryLive.FormComponent, {:saved, entry}}, socket) do
    {:noreply, stream_insert(socket, :entries, entry)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    entry = Ash.get!(Wedid.Diaries.Entry, id, actor: socket.assigns.current_user)
    Ash.destroy!(entry, actor: socket.assigns.current_user)

    {:noreply, stream_delete(socket, :entries, entry)}
  end
end
