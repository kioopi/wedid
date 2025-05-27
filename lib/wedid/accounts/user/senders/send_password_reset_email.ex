defmodule Wedid.Accounts.User.Senders.SendPasswordResetEmail do
  @moduledoc """
  Sends a password reset email
  """

  use AshAuthentication.Sender
  use WedidWeb, :verified_routes

  import Swoosh.Email

  alias Wedid.Mailer

  @impl true
  def send(user, token, _) do
    create_email(user, token)
    |> Mailer.deliver!()
  end

  def create_email(user, token) do
    new()
    |> from({"Vangelis", "wedid@codevise.de"})
    |> to(to_string(user.email))
    |> subject("Reset your WeDid password")
    |> html_body(body(token: token))
  end

  defp body(params) do
    url = url(~p"/password-reset/#{params[:token]}")

    """
    <p>Click this link to reset your password:</p>
    <p><a href="#{url}">#{url}</a></p>
    """
  end
end
