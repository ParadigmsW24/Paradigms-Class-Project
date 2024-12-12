defmodule TermProject.Game do
  @moduledoc """
  Handles the core game logic and state for each game instance.
  Uses PubSub for state synchronization through lobby channels.
  """

  use GenServer

  alias TermProject.GameState
  alias Phoenix.PubSub

  # Public API

  @doc """
  Starts a new game instance for a specific match.
  The match_id corresponds to the match_id from LobbyServer.
  """
  def start_link(match_id) do
    GenServer.start_link(__MODULE__, %{match_id: match_id}, name: {:global, match_id})
  end

  @doc """
  Spawns a unit for a specific player in the game.
  Broadcasts the update through PubSub to sync all players.
  """
  def spawn_unit(match_id, unit_type, player_id) do
    GenServer.call({:global, match_id}, {:spawn_unit, unit_type, player_id})
  end

  @doc """
  Retrieves the current game state for a match.
  Used by clients to sync their local state.
  """
  def get_state(match_id) do
    IO.inspect(match_id, label: "Match ID in Game.get_state")
    state = GenServer.call({:global, match_id}, :get_state)
    #IO.inspect(state, label: "Game State")
    state
  end


  # GenServer Callbacks

  @impl true
  def init(%{match_id: match_id}) do
    IO.puts("Starting Game server for #{match_id}")
    :timer.send_interval(100, :tick)
    # Initialize game state when lobby transitions to "playing" state
    initial_state = %{
      match_id: match_id,  # Same as match_id for correlation
      game_state: GameState.new(),
      players: %{}  # Populated from lobby players
    }

    # Subscribe to two PubSub channels:
    # "game:#{match_id}" - For game-specific events (unit spawns, combat, etc)
    # "lobby:#{match_id}" - For lobby events (player joins/leaves, game start/end)
    PubSub.subscribe(TermProject.PubSub, "game:#{match_id}")
    PubSub.subscribe(TermProject.PubSub, "lobby:#{match_id}")

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:spawn_unit, unit_type, player_id}, _from, state) do
    updated_state = GameState.apply_action(state.game_state, {:create_unit, unit_type})
    broadcast_game_update(state.match_id, updated_state)

    {:reply, :ok, %{state | game_state: updated_state}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state.game_state, state}
  end

  @impl true
  def handle_info({:player_action, player_id, action}, state) do
    updated_state = GameState.apply_action(state.game_state, action)
    broadcast_game_update(state.match_id, updated_state)

    {:noreply, %{state | game_state: updated_state}}
  end

  @impl true
  def handle_info(:game_started, state) do
    # Initialize game state when all players are ready
    {:noreply, state}
  end

  @impl true
  def handle_info(:game_ended, state) do
    # Clean up game state
    {:stop, :normal, state}
  end

  def handle_info(:tick, state) do
    # Update units' positions here
    updated_units = Enum.map(state.game_state.units, fn unit ->
      # Move the unit 5 pixels to the right each tick
      Map.update!(unit, :position, fn pos -> %{pos | x: pos.x + 5} end)
    end)

    updated_state = %{state.game_state | units: updated_units}
    broadcast_game_update(state.match_id, updated_state)

    {:noreply, %{state | game_state: updated_state}}
  end

  # Private Helpers

  defp broadcast_game_update(match_id, game_state) do
    PubSub.broadcast(
      TermProject.PubSub,
      "game:#{match_id}",
      {:game_state_update, game_state}
    )
  end

  def handle_info(:start_countdown, state) do
    # Do nothing and just continue running
    {:noreply, state}
  end

  def handle_info({:game_state_update, _new_state}, state) do
    # No action needed, just ignore
    {:noreply, state}
  end

end
