defmodule WedidWeb.Locale do
  @moduledoc """
  Helper functions for managing application locales and translations.
  """

  @doc """
  Returns a list of all supported locales with their display information.
  """
  def supported_locales do
    [
      %{code: "en", name: "English", flag: "🇺🇸"},
      %{code: "de", name: "Deutsch", flag: "🇩🇪"}
    ]
  end

  @doc """
  Returns the current locale being used by Gettext.
  """
  def current_locale do
    Gettext.get_locale(WedidWeb.Gettext)
  end

  @doc """
  Returns the locale information for a given locale code.
  """
  def locale_info(locale_code) do
    Enum.find(supported_locales(), fn %{code: code} -> code == locale_code end)
  end

  @doc """
  Returns the display name for a given locale code.
  """
  def locale_name(locale_code) do
    case locale_info(locale_code) do
      %{name: name} -> name
      nil -> locale_code
    end
  end

  @doc """
  Returns the flag emoji for a given locale code.
  """
  def locale_flag(locale_code) do
    case locale_info(locale_code) do
      %{flag: flag} -> flag
      nil -> "🌐"
    end
  end

  @doc """
  Returns true if the given locale code is supported.
  """
  def supported_locale?(locale_code) do
    locale_code in Gettext.known_locales(WedidWeb.Gettext)
  end
end