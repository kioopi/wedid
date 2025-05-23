defmodule WedidWeb.PageController do
  use WedidWeb, :controller
  require Ash.Query

  alias Wedid.Accounts.User
  alias Wedid.Diaries
  alias Diaries.Entry

  def home(conn, _params) do
    current_user = conn.assigns[:current_user]

    {:ok, current_user} = current_user |> Ash.load([couple: :user_count], actor: current_user)

    render(conn, :home, get_assigns(current_user))
  end

  defp get_assigns(%User{couple: couple} = user) do
    %{
      couple: couple,
      has_partner: couple.user_count > 1,
      entries:
        Diaries.list_entries!(
          actor: user,
          query: Ash.Query.filter(Entry, user_id != ^user.id)
        ),
      entries_by_day: %{},
      show_couple_link: true
    }
  end

  defp get_assigns(nil), do: %{}
end
