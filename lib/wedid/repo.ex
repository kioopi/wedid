defmodule Wedid.Repo do
  use Ecto.Repo,
    otp_app: :wedid,
    adapter: Ecto.Adapters.Postgres
end
