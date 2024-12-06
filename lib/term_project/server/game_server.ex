defmodule TermProject.Server.GameServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    {:ok, {}}
  end

  # If `password` is a non-empty string or nil, this is a private lobby request.
  def request_lobby(username, password) when is_binary(password) and password != "" do
    GenServer.call(__MODULE__, {:request_private_lobby, username, password})
  end

  # If `password` is an empty string or nil, this is a public lobby request.
  def request_lobby(username, _password) do
    GenServer.call(__MODULE__, {:request_public_lobby, username})
  end

  # Handle request for joining a private lobby
  @impl true
  def handle_call({:request_private_lobby, username, lobby_id}, _from, state) do
    # Attempt to find the private lobby by the given lobby_id (password).
    case :ets.lookup(:Game.Table, lobby_id) do
      [] ->
        # Lobby doesn't exist, create a new one
        new_lobby = %{type: :private, players: [username], status: :waiting, id: lobby_id}
        :ets.insert(:Game.Table, {lobby_id, new_lobby})
        {:reply, {:ok, {lobby_id, new_lobby}}, state}

      [{^lobby_id, existing_lobby}] ->
        # Lobby exists, check if there's room
        cond do
          length(existing_lobby.players) < 2 ->
            updated_lobby = Map.update!(existing_lobby, :players, &[username | &1])
            # If now full, update status
            updated_lobby =
              if length(updated_lobby.players) == 2 do
                Map.put(updated_lobby, :status, :ready)
              else
                updated_lobby
              end

            :ets.insert(:Game.Table, {lobby_id, updated_lobby})
            {:reply, {:ok, {lobby_id, updated_lobby}}, state}

          true ->
            # Lobby full
            {:reply, {:error, :lobby_full}, state}
        end
    end
  end

  # Handle request to join a public lobby
  def handle_call({:request_public_lobby, username}, _from, state) do
    case find_suitable_public_lobby() do
      {:ok, public_lobby_id, public_lobby} ->
        # Add user to the found public lobby
        updated_lobby = Map.update!(public_lobby, :players, &[username | &1])

        updated_lobby =
          if length(updated_lobby.players) == 2 do
            Map.put(updated_lobby, :status, :ready)
          else
            updated_lobby
          end

        :ets.insert(:Game.Table, {public_lobby_id, updated_lobby})
        {:reply, {:ok, {public_lobby_id, updated_lobby}}, state}

      :no_lobby_found ->
        # Create a new public lobby
        new_lobby_id = generate_lobby_id()
        new_lobby = %{type: :public, players: [username], status: :waiting, id: new_lobby_id}
        :ets.insert(:Game.Table, {new_lobby_id, new_lobby})
        {:reply, {:ok, {new_lobby_id, new_lobby}}, state}
    end
  end

  defp find_suitable_public_lobby() do
    # We'll search for any public lobby that is waiting and has less than 2 players.
    :ets.foldl(
      fn {lobby_id, lobby_state}, acc ->
        case acc do
          :no_lobby_found ->
            if lobby_state.type == :public and lobby_state.status == :waiting and
                 length(lobby_state.players) < 2 do
              {:ok, lobby_id, lobby_state}
            else
              :no_lobby_found
            end

          found ->
            found
        end
      end,
      :no_lobby_found,
      :Game.Table
    )
  end

  defp generate_lobby_id() do
    # Simple example: random integer as ID. Consider UUID for production.
    :rand.uniform(1_000_000)
  end
end
