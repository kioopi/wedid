import Config
config :wedid, token_signing_secret: "bq730oKMW4EW2TiHF+HvxivD3bms91LU"
config :bcrypt_elixir, log_rounds: 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :wedid, Wedid.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  database: "wedid_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :wedid, WedidWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "z4UM0oRM1c8sYU3gYCLSXeOWa1CZuNjWUzEG1IDdCesiJ2ujiM1in32pnpEjZamJ",
  server: false

# In test we don't send emails
config :wedid, Wedid.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Insecure encryption to speed up tests
config :bcrypt_elixir, log_rounds: 1

config :ash, :disable_async?, true
config :ash, :policies, show_policy_breakdowns?: true
config :ash, :policies, log_policy_breakdowns?: :error
