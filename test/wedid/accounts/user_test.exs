defmodule Wedid.Accounts.UserTest do
  use Wedid.DataCase

  alias Wedid.Accounts.User
  alias AshAuthentication.Strategy

  @valid_email "test-user@example.com"
  @valid_password "password123"

  describe "User registration" do
    test "user can sign up with email/password" do
      # Create registration attrs
      registration_attrs = %{
        "email" => @valid_email,
        "password" => @valid_password,
        "password_confirmation" => @valid_password
      }

      # Attempt to register the user
      assert {:ok, user} =
               User
               |> Ash.Changeset.for_create(:register_with_password, registration_attrs)
               |> Ash.create(authorize?: false)

      # Verify the user is created with expected attributes
      assert to_string(user.email) == @valid_email
      # Password should be hashed, not stored in plaintext
      assert user.hashed_password != @valid_password
      assert user.hashed_password != nil

      # Verify token is generated
      assert user.__metadata__.token != nil
    end

    test "a couple gets automatically created when a user signs-up" do
      # Create registration attrs
      registration_attrs = %{
        "email" => @valid_email,
        "password" => @valid_password,
        "password_confirmation" => @valid_password
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, registration_attrs)
        |> Ash.create(authorize?: false)

      {:ok, user} = Ash.load(user, [:couple])

      assert user.couple != nil
    end

    test "user cannot register with duplicate email" do
      # Register a user first
      registration_attrs = %{
        "email" => @valid_email,
        "password" => @valid_password,
        "password_confirmation" => @valid_password
      }

      {:ok, _user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, registration_attrs)
        |> Ash.create(authorize?: false)

      # Try to register another user with the same email
      {:error, error} =
        User
        |> Ash.Changeset.for_create(:register_with_password, registration_attrs)
        |> Ash.create(authorize?: false)

      # Verify we get a unique email identity error
      assert error.errors != []

      assert Enum.any?(error.errors, fn e ->
               e.field == :email && String.contains?(e.message, "already been taken")
             end)
    end

    test "user cannot register with mismatched passwords" do
      registration_attrs = %{
        "email" => @valid_email,
        "password" => @valid_password,
        "password_confirmation" => "different_password"
      }

      # Try to register with mismatched passwords
      {:error, error} =
        User
        |> Ash.Changeset.for_create(:register_with_password, registration_attrs)
        |> Ash.create(authorize?: false)

      # Verify we get a password confirmation error
      assert error.errors != []

      assert Enum.any?(error.errors, fn e ->
               e.field == :password_confirmation && String.contains?(e.message, "does not match")
             end)
    end
  end

  describe "User authentication" do
    setup do
      # Create a user for testing login
      registration_attrs = %{
        "email" => @valid_email,
        "password" => @valid_password,
        "password_confirmation" => @valid_password
      }

      {:ok, user} =
        User
        |> Ash.Changeset.for_create(:register_with_password, registration_attrs)
        |> Ash.create(authorize?: false)

      %{user: user}
    end

    test "user can log in with correct email/password", %{user: registered_user} do
      login_attrs = %{
        "email" => @valid_email,
        "password" => @valid_password
      }

      # Get password strategy from user resource
      strategy = AshAuthentication.Info.strategy!(User, :password)

      # Attempt to sign in using strategy.action
      assert {:ok, signed_in_user} = Strategy.action(strategy, :sign_in, login_attrs)

      # Verify the user was authenticated correctly
      assert to_string(signed_in_user.email) == @valid_email
      assert signed_in_user.id == registered_user.id

      # Verify a token was generated
      assert signed_in_user.__metadata__.token != nil
      assert is_binary(signed_in_user.__metadata__.token)

      # Make sure token has expected length
      assert String.length(signed_in_user.__metadata__.token) > 10
    end

    test "user cannot log in with incorrect password" do
      login_attrs = %{
        "email" => @valid_email,
        "password" => "wrong_password"
      }

      # Get password strategy from user resource
      strategy = AshAuthentication.Info.strategy!(User, :password)

      # Attempt to sign in using strategy.action with incorrect password
      assert {:error, error} = Strategy.action(strategy, :sign_in, login_attrs)

      # Check that error is appropriate
      assert match?(%AshAuthentication.Errors.AuthenticationFailed{}, error)

      # Inspect the caused_by field to see the details of the error
      assert %{caused_by: %{errors: [auth_error | _]}} = error
      assert %{caused_by: %{message: message}} = auth_error
      assert message == "Password is not valid"
    end

    test "user cannot log in with non-existent email" do
      login_attrs = %{
        "email" => "nonexistent@example.com",
        "password" => @valid_password
      }

      # Get password strategy from user resource
      strategy = AshAuthentication.Info.strategy!(User, :password)

      # Attempt to sign in using strategy.action with non-existent email
      assert {:error, error} = Strategy.action(strategy, :sign_in, login_attrs)

      # Check that error is appropriate
      assert match?(%AshAuthentication.Errors.AuthenticationFailed{}, error)

      # Inspect the caused_by field to see the details of the error
      assert %{caused_by: %{errors: [auth_error | _]}} = error
      assert %{caused_by: %{message: message}} = auth_error
      assert message == "Query returned no users"
    end
  end
end
