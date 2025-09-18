defmodule WedidWeb.NavbarLanguageSwitcherTest do
  use WedidWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "guest navbar language switcher" do
    test "renders language switcher for guests" do
      html =
        render_component(&WedidWeb.AppComponents.navbar/1, %{
          current_user: nil,
          current_locale: "en"
        })

      assert html =~ "id=\"navbar-language-switcher\""
      assert html =~ "English"
      assert html =~ "Deutsch"
    end
  end
end
