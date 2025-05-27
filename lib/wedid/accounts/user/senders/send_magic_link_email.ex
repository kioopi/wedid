defmodule Wedid.Accounts.User.Senders.SendMagicLinkEmail do
  @moduledoc """
  Sends a magic link email
  """

  use AshAuthentication.Sender
  use WedidWeb, :verified_routes

  import Swoosh.Email
  alias Wedid.Mailer

  @impl true
  def send(user_or_email, token, _) do
    email =
      case user_or_email do
        %{email: email} -> email
        email -> email
      end

    new()
    |> from(Keyword.get(Application.get_env(:wedid, Wedid.Mailer), :sender))
    |> to(to_string(email))
    |> subject("Your WeDid login link")
    |> html_body(body(token: token, email: email))
    |> Mailer.deliver!()
  end

  defp body(params) do
    # NOTE: You may have to change this to match your magic link acceptance URL.

    """
    <p>Hello, #{params[:email]}! Click this link to sign in:</p>
    <p><a href="#{url(~p"/magic_link/#{params[:token]}")}">#{url(~p"/magic_link/#{params[:token]}")}</a></p>
    """
  end
end
