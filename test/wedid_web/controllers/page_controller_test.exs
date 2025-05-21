defmodule WedidWeb.PageControllerTest do
  use WedidWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "WeDid"
  end

  describe "with authenticated user" do
    setup :register_and_log_in_user

    test "GET /", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "Almost there!"
    end
  end
end
