defmodule TermProject.Application do
  @moduledoc """
  The main application module that starts the supervision tree.
  """

  use Application

  def start(_type, _args) do
    :ets.new(Game.Table, [:named_table, :public, :set, {:read_concurrency, true}])

    children = [
      # Start the Ecto repository
      TermProject.Repo,
      # Start the Telemetry supervisor
      TermProjectWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: TermProject.PubSub},
      # Start the Endpoint (http/https)
      TermProjectWeb.Endpoint,
      # Start the Game server
      {TermProject.Game, :test_match_id},
      # Start the Game server
      TermProject.Game.LobbyServer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html for strategies and options
    opts = [strategy: :one_for_one, name: TermProject.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
