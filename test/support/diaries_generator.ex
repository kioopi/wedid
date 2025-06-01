defmodule Wedid.Diaries.Generator do
  use Ash.Generator

  alias Wedid.Diaries.{Entry, Tag}
  alias Wedid.Accounts.Generator, as: AccountsGenerator

  # Generator for a Entry resource
  def entry(opts \\ []) do
    changeset_generator(
      Entry,
      :create,
      actor: opts[:actor] || generate(AccountsGenerator.user()),
      defaults: [
        content: Faker.Lorem.sentence(),
        created_at: Faker.Date.between(~U[2025-01-11 00:00:00Z], ~U[2025-05-13 00:00:00Z])
      ],
      overrides: opts
    )
  end

  def tag(opts \\ []) do
    changeset_generator(
      Tag,
      :create,
      actor: opts[:actor] || generate(AccountsGenerator.user()),
      defaults: [
        name: Faker.Food.ingredient(),
        color: "",
        icon: Faker.Internet.slug()
      ],
      overrides: opts
    )
  end
end
