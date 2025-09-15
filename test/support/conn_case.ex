defmodule WedidWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use WedidWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate
  alias Wedid.Accounts.{Generator, User}

  using do
    quote do
      # The default endpoint for testing
      @endpoint WedidWeb.Endpoint

      use WedidWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import WedidWeb.ConnCase
    end
  end

  setup tags do
    Wedid.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def register_and_log_in_user(%{conn: conn} = context) do
    user = Generator.generate(Generator.user())
    strategy = AshAuthentication.Info.strategy!(User, :password)

    {:ok, user} =
      AshAuthentication.Strategy.action(strategy, :sign_in, %{
        email: user.email,
        password: "password"
      })

    Gettext.put_locale(WedidWeb.Gettext, "en")

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Plug.Conn.put_session(:locale, "en")
      |> AshAuthentication.Plug.Helpers.store_in_session(user)
      |> Plug.Conn.assign(:current_user, user)

    # Ensure the modified conn is placed back into the context
    context
    |> Map.put(:user, user)
    |> Map.put(:conn, conn)
  end
end
