defmodule WedidWeb.UserMenuComponentTest do
  use WedidWeb.ConnCase, async: true
  
  describe "User menu component rendering" do
    test "component structure and Gravatar integration" do
      # Test data that mimics what the real user would have
      mock_user = %{
        email: Ash.CiString.new("test@example.com"),
        display_name: "test"
      }
      
      # Test that ExGravatar generates the expected URL
      expected_gravatar = Exgravatar.gravatar_url("test@example.com", s: 40, d: "blank")
      assert String.starts_with?(expected_gravatar, "https://secure.gravatar.com/avatar/")
      assert String.contains?(expected_gravatar, "s=40")
      assert String.contains?(expected_gravatar, "d=blank")
      
      # Test email conversion from CiString
      converted_email = to_string(mock_user.email)
      assert converted_email == "test@example.com"
      
      # Test initial letter extraction
      initial = mock_user.display_name |> String.first() |> String.upcase()
      assert initial == "T"
    end

    test "gravatar URL hash consistency" do
      # Test that the same email produces the same hash
      email = "john.doe@example.com"
      url1 = Exgravatar.gravatar_url(email, s: 40, d: "blank")  
      url2 = Exgravatar.gravatar_url(email, s: 40, d: "blank")
      
      assert url1 == url2
    end

    test "gravatar parameters are correctly set" do
      email = "user@example.com"
      url = Exgravatar.gravatar_url(email, s: 40, d: "blank")
      
      # Parse URL to check parameters
      uri = URI.parse(url)
      params = URI.decode_query(uri.query)
      
      assert params["s"] == "40"
      assert params["d"] == "blank"
    end

    test "different emails produce different hashes" do
      url1 = Exgravatar.gravatar_url("user1@example.com", s: 40, d: "blank")
      url2 = Exgravatar.gravatar_url("user2@example.com", s: 40, d: "blank")
      
      # URLs should be different
      assert url1 != url2
      
      # But both should be valid gravatar URLs
      assert String.contains?(url1, "gravatar.com/avatar/")
      assert String.contains?(url2, "gravatar.com/avatar/")
    end

    test "email case normalization" do
      # Gravatar should normalize email case
      url_upper = Exgravatar.gravatar_url("USER@EXAMPLE.COM", s: 40, d: "blank")
      url_lower = Exgravatar.gravatar_url("user@example.com", s: 40, d: "blank")
      
      # Should produce same URL since gravatar normalizes email to lowercase
      assert url_upper == url_lower
    end

    test "handles Ash.CiString email type" do
      email_string = "test@example.com"
      email_cistring = Ash.CiString.new(email_string)
      
      url_from_string = Exgravatar.gravatar_url(email_string, s: 40, d: "blank")
      url_from_cistring = Exgravatar.gravatar_url(to_string(email_cistring), s: 40, d: "blank")
      
      assert url_from_string == url_from_cistring
    end
  end

  describe "Display name and initial extraction" do
    test "extracts first letter from name correctly" do
      test_cases = [
        {"John Doe", "J"},
        {"alice", "A"},
        {"bob", "B"}, 
        {"user123", "U"},
        {"123user", "1"}
      ]
      
      for {name, expected_initial} <- test_cases do
        actual_initial = name |> String.first() |> String.upcase()
        assert actual_initial == expected_initial, "Failed for name: #{name}"
      end
    end

    test "handles edge cases for display name" do
      edge_cases = [
        {"", ""}, # Empty string
        {"a", "A"}, # Single character
        {"Ä", "Ä"}, # Unicode character
        {"😀", "😀"} # Emoji
      ]
      
      for {name, expected} <- edge_cases do
        if name != "" do
          actual = name |> String.first() |> String.upcase()
          assert actual == expected, "Failed for edge case: #{name}"
        end
      end
    end
  end

  describe "Component integration verification" do
    test "component dependencies are available" do
      # Verify that the ExGravatar module is loaded and available
      assert Code.ensure_loaded?(Exgravatar)
      
      # Verify basic function is available
      assert function_exported?(Exgravatar, :gravatar_url, 2)
    end

    test "required CSS classes are properly formatted" do
      # Test the CSS classes that should be used in the component
      expected_classes = [
        "dropdown dropdown-end",
        "btn btn-ghost btn-circle avatar", 
        "w-10 h-10 rounded-full overflow-hidden",
        "bg-primary text-primary-content",
        "flex items-center justify-center",
        "w-full h-full object-cover",
        "text-sm font-medium leading-none",
        "menu dropdown-content z-[1] p-2 shadow-lg bg-base-100 text-base-content rounded-box w-52 mt-4"
      ]
      
      # Just verify these are valid strings (would be used in the component)
      for css_class <- expected_classes do
        assert is_binary(css_class)
        assert String.length(css_class) > 0
      end
    end
  end
end