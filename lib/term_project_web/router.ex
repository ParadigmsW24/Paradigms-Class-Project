defmodule TermProjectWeb.Router do
  alias TermProject.Game
  alias Hex.API.Auth
  use TermProjectWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TermProjectWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TermProjectWeb do
    pipe_through :browser

    get "/signup", AuthController, :new
    post "/signup", AuthController, :create

    live_session :default, on_mount: {TermProjectWeb.AuthLive, :on_mount} do
      live "/testing", GameLive
    end
    live "/game", GameLive

    live "/", LobbyLive, :index
    live "/lobby/:id", LobbyRoomLive, :show

    live "/register", RegistrationLive, :new
    live "/login", LoginLive, :new
    live "/game/:id", GameLive
  end

  scope "/auth", TermProjectWeb do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end
  # Other scopes may use custom stacks.
  # scope "/api", TermProjectWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:term_project, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TermProjectWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
