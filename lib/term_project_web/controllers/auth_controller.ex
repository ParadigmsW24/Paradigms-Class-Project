defmodule TermProjectWeb.AuthController do
  use TermProjectWeb, :controller
  alias TermProject.Accounts
  alias TermProject.Accounts.LoginUser

  plug Ueberauth

  def new(conn, _params) do
    changeset = Accounts.change_user(%LoginUser{})
    render(conn, "signup.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Account created successfully!")
        |> redirect(to: "/login")

      {:error, changeset} ->
        render(conn, "signup.html", changeset: changeset)
    end
  end

  def login_page(conn, _params) do
    render(conn, "login.html", conn: conn)
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Logged in successfully!")
        |> redirect(to: "/?username=bhavnoor")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> redirect(to: "/signup")
    end
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/signup")
  end

  # GitHub OAuth Routes
  def request(conn, _params) do
    redirect(conn, external: Ueberauth.Strategy.Helpers.callback_url(conn))
  end

  def single_word(string) do
    string
    |> String.trim()
    |> String.split(~r/\s+/)
    |> List.first()
  end

  def callback(
        %{assigns: %{ueberauth_auth: %Ueberauth.Auth{info: info, credentials: credentials}}} =
          conn,
        _params
      ) do
    IO.inspect(info)
    IO.puts("callback for oauth")
    auth_provider = nil

    if info.image == nil do
      auth_provider = "github"
    end

    user_params = %{
      email: info.email,
      full_name: info.name || info.nickname || info.first_name || "oauth user",
      token: credentials.token,
      auth_provider: auth_provider || "google"
    }

    case Accounts.create_or_update_user(user_params) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome #{user.full_name}!")
        |> redirect(to: "/?username=#{single_word(user.full_name)}")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to save user information.")
        |> redirect(to: "/")
    end
  end

  def callback(%{assigns: %{ueberauth_failure: failure}} = conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed: #{inspect(failure)}")
    |> redirect(to: "/")
  end
end
