defmodule Wedid.Accounts.User.Senders.SendNewUserConfirmationEmail do
  @moduledoc """
  Sends an email for a new user to confirm their email address.
  """

  use AshAuthentication.Sender
  use WedidWeb, :verified_routes

  import Swoosh.Email

  alias Wedid.Mailer

  @impl true
  def send(user, token, _) do
    create_email(user, token) |> Mailer.deliver!()
  end

  def create_email(user, token) do
    new()
    # TODO: Move this to a config file
    |> from(Keyword.get(Application.get_env(:wedid, Wedid.Mailer), :sender))
    |> to(to_string(user.email))
    |> subject("WeDid Confirm your email address")
    |> html_body(body(token: token))
  end

  defp body(params) do
    url = url(~p"/confirm_new_user/#{params[:token]}")

    """
    <p>Click this link to confirm your email for WeDid:</p>
    <p><a href="#{url}">#{url}</a></p>
    """
  end
end
