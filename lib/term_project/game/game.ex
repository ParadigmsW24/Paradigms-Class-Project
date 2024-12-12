defmodule TermProject.Game do
  @moduledoc """
  Handles the core game logic and state for each game instance.
  Uses PubSub for state synchronization through lobby channels.
  """

  use GenServer

  alias TermProject.GameState
  alias TermProject.Game.LobbyServer
  alias Phoenix.PubSub

  @tick_rate 100

  # Public API

  @doc """
  Starts a new game instance for a specific lobby_id.
  """
  def start_link(%{lobby_id: lobby_id, players: players}) do
    GenServer.start_link(__MODULE__, %{lobby_id: lobby_id, players: players},
      name: {:global, {:game_server, lobby_id}})
  end

  @doc """
  Spawns a unit for a specific player in the game.
  Broadcasts the update through PubSub to sync all players.
  """
  def spawn_unit(lobby_id, unit_type, player_id) do
    GenServer.call({:global, {:game_server, lobby_id}}, {:spawn_unit, unit_type, player_id})
  end

  @doc """
  Retrieves the current game state for a lobby.
  Used by clients to sync their local state.
  """
  def get_state(lobby_id) do
    try do
      case :global.whereis_name({:game_server, lobby_id}) do
        :undefined ->
          # No game process exists
          {:error, :game_not_found}

        pid when is_pid(pid) ->
          # Call with timeout
          case GenServer.call(pid, :get_state, 5000) do
            game_state -> {:ok, game_state}
          end
      end
    catch
      :exit, _ -> {:error, :game_not_available}
    end
  end

  # GenServer Callbacks

  # In game.ex
  @impl true
  def init(%{lobby_id: lobby_id, players: player_mapping}) do
    # Debug
    IO.puts("#{DateTime.utc_now()} - Game server init starting")
    IO.inspect(player_mapping, label: "Player mapping in init")

    game_state = GameState.new()

    initial_state = %{
      lobby_id: lobby_id,
      # Update GameState with players
      game_state: %{game_state | players: player_mapping},
      players: player_mapping
    }

    IO.inspect(initial_state, label: "Initial game state")

    PubSub.subscribe(TermProject.PubSub, "game:#{lobby_id}")
    Process.flag(:trap_exit, true)

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:spawn_unit, unit_type, player_id}, _from, state) do
    unit = %{
      type: unit_type,
      position: if(player_id == 1, do: %{x: 100, y: 300}, else: %{x: 900, y: 300}),
      owner: player_id
    }

    updated_game_state = %{state.game_state | units: [unit | state.game_state.units]}

    broadcast_game_update(state.lobby_id, updated_game_state)
    {:reply, :ok, %{state | game_state: updated_game_state}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state.game_state, state}
  end

  @impl true
  def handle_info({:game_state_update, updated_game_state}, state) do
    # Simply update the state with the new game state
    {:noreply, %{state | game_state: updated_game_state}}
  end

  @impl true
  def handle_info({:player_action, _player_id, action}, state) do
    updated_game_state = GameState.apply_action(state.game_state, action)
    broadcast_game_update(state.lobby_id, updated_game_state)
    {:noreply, %{state | game_state: updated_game_state}}
  end

  @impl true
  def handle_info(:game_started, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:game_ended, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(unknown_message, state) do
    IO.warn("Received unknown message in Game server: #{inspect(unknown_message)}")
    {:noreply, state}
  end

  # Private Helpers
  defp broadcast_game_update(lobby_id, game_state) do
    Phoenix.PubSub.broadcast(
      TermProject.PubSub,
      "game:#{lobby_id}",
      {:game_state_update, game_state}
    )
  end
end

# defmodule TermProject.Game do
#   @moduledoc """
#   Handles the core game logic and state for each game instance.
#   Uses PubSub for state synchronization through lobby channels.
#   """

#   use GenServer

#   alias TermProject.GameState
#   alias TermProject.Game.LobbyServer
#   alias Phoenix.PubSub

#   # Public API

#   @doc """
#   Starts a new game instance for a specific lobby_id.
#   """
#   def start_link(lobby_id) do
#     GenServer.start_link(__MODULE__, %{lobby_id: lobby_id},
#       name: {:global, {:game_server, lobby_id}}
#     )
#   end

#   @doc """
#   Spawns a unit for a specific player in the game.
#   Broadcasts the update through PubSub to sync all players.
#   """
#   def spawn_unit(lobby_id, unit_type, player_id) do
#     GenServer.call({:global, {:game_server, lobby_id}}, {:spawn_unit, unit_type, player_id})
#   end

#   @doc """
#   Retrieves the current game state for a lobby.
#   Used by clients to sync their local state.
#   """
#   def get_state(lobby_id) do
#     try do
#       case :global.whereis_name({:game_server, lobby_id}) do
#         :undefined ->
#           # No game process exists
#           {:error, :game_not_found}

#         pid when is_pid(pid) ->
#           # Call with timeout
#           case GenServer.call(pid, :get_state, 5000) do
#             game_state -> {:ok, game_state}
#           end
#       end
#     catch
#       :exit, _ -> {:error, :game_not_available}
#     end
#   end

#   # GenServer Callbacks

#   @impl true
#   def init(%{lobby_id: lobby_id}) do
#     # Get lobby info
#     {:ok, lobby} = LobbyServer.get_lobby(lobby_id)

#     # Map players to sides (player 1 = host, player 2 = other player)
#     [host | others] = Map.keys(lobby.players)

#     player_mapping = %{
#       1 => host,
#       2 => Enum.at(others, 0)
#     }

#     # Initialize state with player info
#     initial_state = %{
#       lobby_id: lobby_id,
#       game_state: GameState.new(),
#       players: player_mapping
#     }

#     # Subscribe to updates
#     PubSub.subscribe(TermProject.PubSub, "game:#{lobby_id}")
#     Process.flag(:trap_exit, true)

#     {:ok, initial_state}
#   end

#   @impl true
#   def handle_call({:spawn_unit, unit_type, _player_id}, _from, state) do
#     updated_game_state = GameState.apply_action(state.game_state, {:create_unit, unit_type})
#     broadcast_game_update(state.lobby_id, updated_game_state)
#     {:reply, :ok, %{state | game_state: updated_game_state}}
#   end

#   @impl true
#   def handle_call(:get_state, _from, state) do
#     {:reply, state.game_state, state}
#   end

#   @impl true
#   def handle_info({:player_action, _player_id, action}, state) do
#     updated_game_state = GameState.apply_action(state.game_state, action)
#     broadcast_game_update(state.lobby_id, updated_game_state)
#     {:noreply, %{state | game_state: updated_game_state}}
#   end

#   @impl true
#   def handle_info(:game_started, state) do
#     # Update state if needed at game start
#     {:noreply, state}
#   end

#   @impl true
#   def handle_info(:game_ended, state) do
#     # Clean up game state if necessary
#     {:stop, :normal, state}
#   end

#   # Private Helpers
#   defp broadcast_game_update(lobby_id, game_state) do
#     Phoenix.PubSub.broadcast(
#       TermProject.PubSub,
#       "game:#{lobby_id}",
#       {:game_state_update, game_state}
#     )
#   end
# end
