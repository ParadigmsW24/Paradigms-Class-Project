defmodule TermProjectWeb.SessionController do
  use TermProjectWeb, :controller
  alias TermProject.Accounts

  # Display the login form
  def new(conn, _params) do
    render(conn, "login.html", layout: false)
  end

  # Handle the login form submission
  def create(conn, %{"user" => %{"username" => username, "password" => password}}) do
    case Accounts.authenticate_user(username, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Logged in successfully.")
        |> redirect(to: ~p"/lobby")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid username or password.")
        |> render(:login, layout: false)
    end
  end

  # Handle guest login
  def guest_login(conn, %{"guest_username" => guest_username}) do
    # Optionally, you can check if the username is already taken by a registered user
    conn
    |> put_session(:guest_username, guest_username)
    |> put_flash(:info, "Logged in as guest.")
    |> redirect(to: ~p"/lobby")
  end

  # Logout action
  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: ~p"/login")
  end
end
