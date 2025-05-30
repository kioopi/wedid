defmodule Wedid.Repo.Migrations.EntriesMigration do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:entries, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :content, :text, null: false
      add :created_at, :utc_datetime, null: false

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :couple_id,
          references(:couples,
            column: :id,
            name: "entries_couple_id_fkey",
            type: :uuid,
            prefix: "public"
          )

      add :user_id,
          references(:users,
            column: :id,
            name: "entries_user_id_fkey",
            type: :uuid,
            prefix: "public"
          )
    end
  end

  def down do
    drop constraint(:entries, "entries_couple_id_fkey")

    drop constraint(:entries, "entries_user_id_fkey")

    drop table(:entries)
  end
end
