Application.ensure_all_started(:wedid) # Ensure the app and its deps (like the Repo) are started
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Wedid.Repo, :manual)
