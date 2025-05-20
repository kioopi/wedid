defmodule WedidWeb.PageController do
  use WedidWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
