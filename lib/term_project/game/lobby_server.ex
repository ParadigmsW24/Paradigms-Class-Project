# defmodule TermProject.Game.LobbyServer do
#   use GenServer

#   # Client API

#   def start_link(_) do
#     GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
#   end

#   def create_lobby(max_players, password \\ nil) do
#     GenServer.call(__MODULE__, {:create_lobby, max_players, password})
#   end

#   def list_lobbies do
#     case :ets.info(:lobbies) do
#       :undefined ->
#         []

#       _ ->
#         :ets.match_object(:lobbies, {:_, :_})
#         |> Enum.map(fn {_, lobby} -> lobby end)
#     end
#   end

#   def join_lobby(lobby_id, username, password \\ nil) do
#     GenServer.call(__MODULE__, {:join_lobby, lobby_id, username, password})
#   end

#   def set_ready_status(lobby_id, username, ready_status) do
#     GenServer.call(__MODULE__, {:set_ready_status, lobby_id, username, ready_status})
#   end

#   def get_lobby(lobby_id) do
#     GenServer.call(__MODULE__, {:get_lobby, lobby_id})
#   end

#   def close_lobby(lobby_id, username) do
#     GenServer.call(__MODULE__, {:close_lobby, lobby_id, username})
#   end

#   def find_and_join_lobby(username) do
#     GenServer.call(__MODULE__, {:find_and_join_lobby, username})
#   end

#   # Server Callbacks

#   def init(_state) do
#     :ets.new(:lobbies, [:set, :named_table, :public])
#     {:ok, %{}}
#   end

#   def handle_call({:create_lobby, max_players, password}, _from, state) do
#     lobby_id = :erlang.unique_integer([:positive])

#     # lobby = %{
#     #   id: lobby_id,
#     #   max_players: max_players,
#     #   players: %{},
#     #   host: nil
#     # }
#     lobby = %{
#       id: lobby_id,
#       max_players: max_players,
#       players: %{},
#       host: nil,
#       password: case password do
#         password when is_binary(password) -> hash_password(password)
#         _ -> nil
#       end
#     }
#     # lobby = %{
#     #   id: lobby_id,
#     #   max_players: max_players,
#     #   players: %{},
#     #   host: nil,
#     #   password: if is_binary(password), do: hash_password(password), else: nil
#     # }

#     # Add password only if it exists and is binary
#     lobby =
#       case password do
#         password when is_binary(password) -> Map.put(lobby, :password, hash_password(password))
#         nil -> lobby
#       end

#     :ets.insert(:lobbies, {lobby_id, lobby})
#     Phoenix.PubSub.broadcast(TermProject.PubSub, "lobbies", :lobby_updated)
#     {:reply, {:ok, lobby_id}, state}
#   end

#   def handle_call({:join_lobby, lobby_id, username, password}, _from, state) do
#     with {:ok, lobby} <- lookup_lobby(lobby_id),
#          :ok <- validate_password(lobby, password),
#          :ok <- validate_player_status(lobby, username),
#          :ok <- validate_lobby_capacity(lobby) do
#       updated_lobby = update_lobby_state(lobby, username)
#       :ets.insert(:lobbies, {lobby_id, updated_lobby})
#       Phoenix.PubSub.broadcast(TermProject.PubSub, "lobby:#{lobby_id}", :lobby_updated)
#       {:reply, :ok, state}
#     else
#       # {:error, reason} -> {:reply, {:error, reason}, state}
#       {:error, :no_password_required} -> {:reply, {:error, "This lobby does not require a password."}, state}
#       {:error, :incorrect_password} -> {:reply, {:error, "Incorrect password."}, state}
#       {:error, reason} -> {:reply, {:error, reason}, state}
#     end
#   end

#   def handle_call({:set_ready_status, lobby_id, username, ready_status}, _from, state) do
#     with {:ok, lobby} <- lookup_lobby(lobby_id),
#          :ok <- validate_player_exists(lobby, username),
#          {:ok, updated_lobby} <- update_ready_status(lobby, username, ready_status) do
#       :ets.insert(:lobbies, {lobby_id, updated_lobby})
#       Phoenix.PubSub.broadcast(TermProject.PubSub, "lobby:#{lobby_id}", :lobby_updated)
#       check_all_ready(lobby_id)
#       {:reply, :ok, state}
#     end
#   end

#   def handle_call({:get_lobby, lobby_id}, _from, state) do
#     case lookup_lobby(lobby_id) do
#       {:ok, lobby} -> {:reply, {:ok, lobby}, state}
#       error -> {:reply, error, state}
#     end
#   end

#   def handle_call({:close_lobby, lobby_id, username}, _from, state) do
#     with {:ok, lobby} <- lookup_lobby(lobby_id),
#          :ok <- validate_is_host(lobby, username) do
#       :ets.delete(:lobbies, lobby_id)
#       Phoenix.PubSub.broadcast(TermProject.PubSub, "lobbies", :lobby_updated)
#       Phoenix.PubSub.broadcast(TermProject.PubSub, "lobby:chat:#{lobby_id}", :lobby_closed)
#       {:reply, :ok, state}
#     end
#   end

#   def handle_call({:find_and_join_lobby, username}, _from, state) do
#     available_lobbies =
#       :ets.tab2list(:lobbies)
#       |> Enum.map(fn {_id, lobby} -> lobby end)
#       |> Enum.filter(fn lobby ->
#         map_size(lobby.players) < lobby.max_players and is_nil(lobby.password)
#       end)

#     case available_lobbies do
#       [] ->
#         {:reply, {:error, :no_available_lobby}, state}

#       lobbies ->
#         lobby = Enum.random(lobbies)

#         case join_lobby(lobby.id, username) do
#           :ok -> {:reply, {:ok, lobby.id}, state}
#           {:error, reason} -> {:reply, {:error, reason}, state}
#         end
#     end
#   end

#   def check_all_ready(lobby_id) do
#     case :ets.lookup(:lobbies, lobby_id) do
#       [{^lobby_id, lobby}] ->
#         all_ready = Enum.all?(lobby.players, fn {_username, %{ready: ready}} -> ready end)

#         if all_ready do
#           Phoenix.PubSub.broadcast(TermProject.PubSub, "lobby:#{lobby_id}", :start_countdown)
#           :ok
#         else
#           {:error, :not_all_ready}
#         end

#       [] ->
#         {:error, :lobby_not_found}
#     end
#   end

#   # Helper function to handle joining a lobby internally
#   defp lookup_lobby(lobby_id) do
#     case :ets.lookup(:lobbies, lobby_id) do
#       [{^lobby_id, lobby}] -> {:ok, lobby}
#       [] -> {:error, :lobby_not_found}
#     end
#   end

#   defp validate_password(%{password: nil}, nil), do: :ok
#   defp validate_password(%{password: nil}, _), do: {:error, :no_password_required}
#   defp validate_password(%{password: hash}, password) when is_binary(hash) do
#     if check_password(hash, password), do: :ok, else: {:error, :incorrect_password}
#   end
#   defp validate_password(_, _), do: {:error, :invalid_lobby_structure}

#   # defp validate_password(%{password: nil}, _password), do: :ok
#   # defp validate_password(%{password: hash}, password) when is_binary(hash) do
#   #   if check_password(hash, password), do: :ok, else: {:error, :incorrect_password}
#   # end
#   # defp validate_password(_, _), do: {:error, :invalid_lobby_structure}
#   # defp validate_password(lobby, password) do
#   #   if check_password(lobby.password, password) do
#   #     :ok
#   #   else
#   #     {:error, :incorrect_password}
#   #   end
#   # end

#   defp validate_player_status(lobby, username) do
#     if Map.has_key?(lobby.players, username) do
#       {:error, :already_in_lobby}
#     else
#       :ok
#     end
#   end

#   defp validate_lobby_capacity(lobby) do
#     if map_size(lobby.players) < lobby.max_players do
#       :ok
#     else
#       {:error, :lobby_full}
#     end
#   end

#   defp update_lobby_state(lobby, username) do
#     updated_players = Map.put(lobby.players, username, %{ready: false})
#     host = if map_size(lobby.players) == 0, do: username, else: lobby.host
#     %{lobby | players: updated_players, host: host}
#   end

#   defp validate_is_host(lobby, username) do
#     if lobby.host == username do
#       :ok
#     else
#       {:error, :not_host}
#     end
#   end

#   defp validate_player_exists(lobby, username) do
#     if Map.has_key?(lobby.players, username) do
#       :ok
#     else
#       {:error, :player_not_found}
#     end
#   end

#   defp update_ready_status(lobby, username, ready_status) do
#     updated_players =
#       Map.update!(lobby.players, username, fn player ->
#         %{player | ready: ready_status}
#       end)

#     {:ok, %{lobby | players: updated_players}}
#   end

#   # hashing password function
#   defp hash_password(nil), do: nil
#   defp hash_password(password), do: Bcrypt.hash_pwd_salt(password)
#   defp check_password(nil, _password), do: true
#   defp check_password(hash_password, password), do: Bcrypt.verify_pass(password, hash_password)
# end

defmodule TermProject.Game.LobbyServer do
  use GenServer

  # Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def create_lobby(max_players, password \\ nil) do
    GenServer.call(__MODULE__, {:create_lobby, max_players, password})
  end

  def list_lobbies do
    case :ets.info(:lobbies) do
      :undefined -> []
      _ ->
        :ets.match_object(:lobbies, {:_, :_})
        |> Enum.map(fn {_, lobby} -> lobby end)
    end
  end

  def join_lobby(lobby_id, username, password \\ nil) do
    GenServer.call(__MODULE__, {:join_lobby, lobby_id, username, password})
  end

  def set_ready_status(lobby_id, username, ready_status) do
    GenServer.call(__MODULE__, {:set_ready_status, lobby_id, username, ready_status})
  end

  def get_lobby(lobby_id) do
    GenServer.call(__MODULE__, {:get_lobby, lobby_id})
  end

  def close_lobby(lobby_id, username) do
    GenServer.call(__MODULE__, {:close_lobby, lobby_id, username})
  end

  def find_and_join_lobby(username) do
    GenServer.call(__MODULE__, {:find_and_join_lobby, username})
  end

  # Server Callbacks

  def init(_) do
    :ets.new(:lobbies, [:set, :named_table, :public])
    {:ok, %{}}
  end

  def handle_call({:create_lobby, max_players, password}, _from, state) do
    lobby_id = :erlang.unique_integer([:positive])

    lobby = %{
      id: lobby_id,
      max_players: max_players,
      players: %{},
      host: nil,
      password: (if is_binary(password), do: hash_password(password), else: nil)
    }

    :ets.insert(:lobbies, {lobby_id, lobby})
    Phoenix.PubSub.broadcast(TermProject.PubSub, "lobbies", :lobby_updated)
    {:reply, {:ok, lobby_id}, state}
  end

  def handle_call({:join_lobby, lobby_id, username, password}, _from, state) do
    with {:ok, lobby} <- lookup_lobby(lobby_id),
         :ok <- validate_password_if_needed(lobby, password),
         :ok <- validate_player_status(lobby, username),
         :ok <- validate_lobby_capacity(lobby) do
      updated_lobby = update_lobby_state(lobby, username)
      :ets.insert(:lobbies, {lobby_id, updated_lobby})
      Phoenix.PubSub.broadcast(TermProject.PubSub, "lobby:#{lobby_id}", :lobby_updated)
      {:reply, :ok, state}
    else
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:set_ready_status, lobby_id, username, ready_status}, _from, state) do
    with {:ok, lobby} <- lookup_lobby(lobby_id),
         :ok <- validate_player_exists(lobby, username),
         {:ok, updated_lobby} <- update_ready_status(lobby, username, ready_status) do
      :ets.insert(:lobbies, {lobby_id, updated_lobby})
      Phoenix.PubSub.broadcast(TermProject.PubSub, "lobby:#{lobby_id}", :lobby_updated)
      check_all_ready(lobby_id)
      {:reply, :ok, state}
    end
  end

  def handle_call({:get_lobby, lobby_id}, _from, state) do
    case lookup_lobby(lobby_id) do
      {:ok, lobby} -> {:reply, {:ok, lobby}, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call({:close_lobby, lobby_id, username}, _from, state) do
    with {:ok, lobby} <- lookup_lobby(lobby_id),
         :ok <- validate_is_host(lobby, username) do
      :ets.delete(:lobbies, lobby_id)
      Phoenix.PubSub.broadcast(TermProject.PubSub, "lobbies", :lobby_updated)
      Phoenix.PubSub.broadcast(TermProject.PubSub, "lobby:chat:#{lobby_id}", :lobby_closed)
      {:reply, :ok, state}
    end
  end

  def handle_call({:find_and_join_lobby, username}, _from, state) do
    available_lobbies =
      :ets.tab2list(:lobbies)
      |> Enum.map(fn {_id, lobby} -> lobby end)
      |> Enum.filter(fn lobby ->
        map_size(lobby.players) < lobby.max_players and is_nil(lobby.password)
      end)

    case available_lobbies do
      [] ->
        {:reply, {:error, :no_available_lobby}, state}

      lobbies ->
        lobby = Enum.random(lobbies)
        case join_lobby(lobby.id, username) do
          :ok -> {:reply, {:ok, lobby.id}, state}
          {:error, reason} -> {:reply, {:error, reason}, state}
        end
    end
  end

  def check_all_ready(lobby_id) do
    case :ets.lookup(:lobbies, lobby_id) do
      [{^lobby_id, lobby}] ->
        all_ready = Enum.all?(lobby.players, fn {_username, %{ready: ready}} -> ready end)
        if all_ready do
          Phoenix.PubSub.broadcast(TermProject.PubSub, "lobby:#{lobby_id}", :start_countdown)
          :ok
        else
          {:error, :not_all_ready}
        end
      [] -> {:error, :lobby_not_found}
    end
  end

  # Helper Functions

  defp lookup_lobby(lobby_id) do
    case :ets.lookup(:lobbies, lobby_id) do
      [{^lobby_id, lobby}] -> {:ok, lobby}
      [] -> {:error, :lobby_not_found}
    end
  end

  defp validate_password_if_needed(lobby, password) do
    IO.puts("why are u gay")
    # IO.inspect(lobby.password)
    if Map.has_key?(lobby, :password) and lobby.password != nil do
      IO.puts("Validating password")
      validate_password(lobby, password)
    else
      IO.puts("No password to validate")
      :ok
    end

  end

  defp validate_password(lobby, password) do
    if check_password(lobby.password, password) do
      :ok
    else
      {:error, :incorrect_password}
    end
  end

  defp validate_player_status(lobby, username) do
    if Map.has_key?(lobby.players, username) do
      {:error, :already_in_lobby}
    else
      :ok
    end
  end

  defp validate_lobby_capacity(lobby) do
    if map_size(lobby.players) < lobby.max_players do
      :ok
    else
      {:error, :lobby_full}
    end
  end

  defp update_lobby_state(lobby, username) do
    updated_players = Map.put(lobby.players, username, %{ready: false})
    host = if map_size(lobby.players) == 0, do: username, else: lobby.host
    %{lobby | players: updated_players, host: host}
  end

  defp validate_is_host(lobby, username) do
    if lobby.host == username do
      :ok
    else
      {:error, :not_host}
    end
  end

  defp validate_player_exists(lobby, username) do
    if Map.has_key?(lobby.players, username) do
      :ok
    else
      {:error, :player_not_found}
    end
  end

  defp update_ready_status(lobby, username, ready_status) do
    updated_players = Map.update!(lobby.players, username, fn player ->
      %{player | ready: ready_status}
    end)
    {:ok, %{lobby | players: updated_players}}
  end

  defp hash_password(nil), do: nil
  defp hash_password(password), do: Bcrypt.hash_pwd_salt(password)
  defp check_password(nil, _password), do: true
  defp check_password(hash_password, password), do: Bcrypt.verify_pass(password, hash_password)
end
