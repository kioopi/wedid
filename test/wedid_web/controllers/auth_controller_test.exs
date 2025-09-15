defmodule WedidWeb.AuthControllerTest do
  use WedidWeb.ConnCase

  describe "sign_out" do
    setup :register_and_log_in_user

    test "successfully signs out user and redirects", %{conn: conn} do
      # Verify user is signed in
      assert get_session(conn, :user_token)
      assert conn.assigns[:current_user]

      # Sign out
      conn = get(conn, ~p"/sign-out")

      # Should redirect to home page
      assert redirected_to(conn) == ~p"/"
      # Check flash message is present (content may vary by locale)
      assert Phoenix.Flash.get(conn.assigns.flash, :info)
    end

    test "clears user session data", %{conn: conn} do
      # Verify user is signed in
      assert get_session(conn, :user_token)

      # Sign out
      conn = get(conn, ~p"/sign-out")

      # Follow redirect to verify session is cleared
      conn = get(conn, redirected_to(conn))

      # Should show unauthenticated content (home page with sign-in links)
      response = html_response(conn, 200)
      # Check for sign-in related content (works in both English and German)
      assert response =~ "sign-in" or response =~ "Anmelden"
    end

    test "handles sign out when not signed in", %{conn: conn} do
      # Clear session to simulate unauthenticated user
      conn = 
        conn
        |> Plug.Conn.clear_session()
        |> Phoenix.ConnTest.init_test_session(%{})

      # Sign out should still work
      conn = get(conn, ~p"/sign-out")

      # Should redirect to home page
      assert redirected_to(conn) == ~p"/"
      # Check flash message is present (content may vary by locale)
      assert Phoenix.Flash.get(conn.assigns.flash, :info)
    end

    test "preserves return_to session value for redirect", %{conn: conn} do
      return_path = "/some-protected-page"
      
      # Set return_to in session
      conn = Plug.Conn.put_session(conn, :return_to, return_path)
      
      # Sign out
      conn = get(conn, ~p"/sign-out")

      # Should redirect to the return_to path
      assert redirected_to(conn) == return_path
    end

    test "does not cause runtime errors (regression test)", %{conn: conn} do
      # This test specifically prevents the AshAuthentication regression
      # where Entry resource incorrectly had AshAuthentication extension
      
      # Verify user is signed in
      assert get_session(conn, :user_token)
      assert conn.assigns[:current_user]

      # Sign out should complete without runtime errors
      conn = get(conn, ~p"/sign-out")

      # Should successfully redirect (not raise RuntimeError about token_resource)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info)
    end
  end
end