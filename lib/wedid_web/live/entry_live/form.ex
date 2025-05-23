defmodule WedidWeb.EntryLive.Form do
  use WedidWeb, :live_view

  on_mount {WedidWeb.LiveUserAuth, :live_user_required}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage entry records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="entry-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:content]} type="text" label="Content" />
        <.input field={@form[:created_at]} type="datetime-local" label="Created at" />

        <.button phx-disable-with="Saving..." variant="primary">Save Entry</.button>
        <.button navigate={return_path(@return_to, @entry)}>Cancel</.button>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    current_user = socket.assigns.current_user

    entry =
      case params["id"] do
        nil -> nil
        id -> Ash.get!(Wedid.Diaries.Entry, id, actor: current_user)
      end

    action = if is_nil(entry), do: "New", else: "Edit"
    page_title = action <> " " <> "Entry"

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(entry: entry)
     |> assign(:page_title, page_title)
     |> assign_form()}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  @impl true
  def handle_event("validate", %{"entry" => entry_params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, entry_params))}
  end

  def handle_event("save", %{"entry" => entry_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: entry_params) do
      {:ok, entry} ->
        notify_parent({:saved, entry})

        socket =
          socket
          |> put_flash(:info, "Entry #{socket.assigns.form.source.type}d successfully")
          |> push_navigate(to: return_path(socket.assigns.return_to, entry))

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{entry: entry}} = socket) do
    form =
      if entry do
        AshPhoenix.Form.for_update(entry, :update,
          as: "entry",
          actor: socket.assigns.current_user
        )
      else
        AshPhoenix.Form.for_create(Wedid.Diaries.Entry, :create,
          as: "entry",
          actor: socket.assigns.current_user
        )
      end

    assign(socket, form: to_form(form))
  end

  defp return_path("index", _entry), do: ~p"/entries"
  defp return_path("show", entry), do: ~p"/entries/#{entry.id}"
end
