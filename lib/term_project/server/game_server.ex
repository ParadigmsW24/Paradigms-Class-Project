defmodule TermProject.Server.GameServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    {:ok, {}}
  end

  # If `password` is an empty string or nil, this is a public lobby request.
  def request_lobby(username, password) when is_binary(password) and password != "" do
    GenServer.call(__MODULE__, {:request_private_lobby, username, password})
  end

  #If `password` is a non-empty string or nil, this is a private lobby request.
  def request_lobby(username, _password) do
    GenServer.call(__MODULE__, {:request_public_lobby, username})
  end

  def search_lobby() do
  end

  @spec create_lobby() :: nil
  def create_lobby() do
  end

  def remove_lobby() do
  end
end
