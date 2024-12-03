defmodule TermProject.Server.GameServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def search_lobby() do
  end

  @spec create_lobby() :: nil
  def create_lobby() do
  end

  def remove_lobby() do
  end

  @impl true
  def init(:ok) do
    {:ok, {}}
  end
end
