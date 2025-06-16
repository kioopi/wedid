IEx.configure(auto_reload: true)

alias Wedid.Accounts
alias Accounts.{User, Couple}
alias Wedid.Diaries
alias Wedid.Diaries.Entry

alias Wedid.Mailer
alias Wedid.Accounts.Generator, as: AccountsGenerator
alias Wedid.Diaries.Generator, as: DiariesGenerator
alias Ash.Generator
alias Ash.Query
alias Ash.Changeset

noauth = [authorize?: false]

# use this to get a user in iex
# user = User.get_by_email!("user@example.com", noauth)
