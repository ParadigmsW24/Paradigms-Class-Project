defmodule TermProject.Server.Lobby do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def add_user() do
  end

  @impl true
  def init(:ok) do
    {:ok, {}}
  end
end
