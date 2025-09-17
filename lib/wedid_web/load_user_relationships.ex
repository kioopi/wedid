defmodule WedidWeb.LoadUserRelationships do
  import Plug.Conn

  @user_relationships [:display_name, :couple, :profile_picture]

  def init(_opts), do: []

  def call(%Plug.Conn{assigns: %{current_user: user}} = conn, _opts) do
    assign(conn, :current_user, load_user_relationships(user))
  end

  def load_user_relationships(user) do
    Ash.load!(user, @user_relationships, actor: user)
  end
end
