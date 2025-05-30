defmodule WedidWeb.EntryLive.Form do
  use WedidWeb, :live_view

  on_mount {WedidWeb.LiveUserAuth, :live_user_required}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="min-h-screen bg-gradient-to-b from-base-100 to-base-200">
        <div class="container mx-auto px-4 py-8 max-w-md">
          <.header>
            <div class="flex items-center gap-2">
              <.heroicon name="hero-pencil-square" class="size-6 text-primary" />
              <span>{@page_title}</span>
            </div>
            <:subtitle>Share your thoughts and moments with your partner</:subtitle>
          </.header>

          <div class="card bg-base-100 shadow-lg mt-6">
            <div class="card-body">
              <.form for={@form} id="entry-form" phx-change="validate" phx-submit="save">
                <.input
                  field={@form[:content]}
                  type="textarea"
                  label="Content"
                  class="textarea textarea-primary"
                />
                <.input
                  field={@form[:created_at]}
                  type="datetime-local"
                  label="Created at"
                  class="input input-primary"
                />

                <div class="flex justify-end gap-2 mt-6">
                  <.button navigate={return_path(@return_to, @entry)} class="btn btn-ghost">
                    <.heroicon name="hero-x-mark" class="size-4 mr-1" /> Cancel
                  </.button>
                  <.button phx-disable-with="Saving..." variant="primary">
                    <.heroicon name="hero-check" class="size-4 mr-1" /> Save Entry
                  </.button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      </div>
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
