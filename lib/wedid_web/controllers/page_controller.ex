defmodule WedidWeb.PageController do
  use WedidWeb, :controller

  alias Wedid.Accounts.User

  def home(conn, _params) do
    current_user = conn.assigns[:current_user]

    {:ok, current_user} = current_user |> Ash.load(couple: :user_count)

    render(conn, :home, get_assigns(current_user))
  end

  defp get_assigns(%User{couple: couple}) do
    %{
      couple: couple,
      has_partner: couple.user_count > 1,
      entries: [],
      entries_by_day: %{}
    }
  end

  defp get_assigns(nil), do: %{}
end
