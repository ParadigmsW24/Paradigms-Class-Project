defmodule TermProjectWeb.GameLive do
  use TermProjectWeb, :live_view
  alias TermProject.Game
  alias TermProject.GameState

  @countdown_start 10

  @impl true
  # In game_live.ex
  def mount(%{"lobby_id" => lobby_id, "username" => username}, _session, socket) do
    lobby_id = String.to_integer(lobby_id)

    IO.puts("Game server running: #{game_server_running?(lobby_id)}")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(TermProject.PubSub, "game:#{lobby_id}")
      Phoenix.PubSub.subscribe(TermProject.PubSub, "lobby:#{lobby_id}")
    end

    # Get lobby info first to get player mapping
    {:ok, lobby} = TermProject.Game.LobbyServer.get_lobby(lobby_id)
    [host | others] = Map.keys(lobby.players)
    player_mapping = %{1 => host, 2 => Enum.at(others, 0)}

    game_state =
      case Game.get_state(lobby_id) do
        {:ok, state} ->
          IO.inspect(state.players, label: "Players in game state")
          state

        {:error, _} ->
          # Initialize with player mapping
          %{GameState.new() | players: player_mapping}
      end

    player_id =
      cond do
        game_state.players[1] == username -> 1
        game_state.players[2] == username -> 2
        true -> nil
      end

    IO.inspect(player_id, label: "Assigned player_id")

    {:ok,
     socket
     |> assign(:lobby_id, lobby_id)
     |> assign(:username, username)
     |> assign(:player_id, player_id)
     |> assign(:game_state, game_state)
     |> assign(:countdown, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="game-container">
      <%= if @countdown do %>
        <div class="countdown">Game starts in <%= @countdown %> seconds...</div>
      <% else %>
        <div class="status-panel">
          <div class="resources">
            <div>Wood: <%= @game_state.resources.amounts.wood %></div>

            <div>Stone: <%= @game_state.resources.amounts.stone %></div>

            <div>Iron: <%= @game_state.resources.amounts.iron %></div>

            <div>Available Workers: <%= @game_state.resources.workers.unused %></div>
          </div>

          <div class="bases">
            <div>Base 1: <%= @game_state.bases[1].health %></div>

            <div>Base 2: <%= @game_state.bases[2].health %></div>
          </div>
        </div>

        <div class="game-controls">
          <button phx-click="spawn_unit" phx-value-type="archer" class="unit-button">
            Spawn Archer
          </button>

          <button phx-click="spawn_unit" phx-value-type="soldier" class="unit-button">
            Spawn Soldier
          </button>

          <button phx-click="spawn_unit" phx-value-type="cavalry" class="unit-button">
            Spawn Cavalry
          </button>

            <div class="dropdown-section">
              <label for="move-to-resource">Move Worker to Resource:</label>
              <select id="move-to-resource" phx-change="move_worker_to_resource">
                <option value="" disabled selected>Choose a resource</option>
                <option value="wood">Wood</option>
                <option value="stone">Stone</option>
                <option value="iron">Iron</option>
              </select>
              <button phx-click="move_worker" phx-value-target="to">Go</button>
            </div>

            <div class="dropdown-section">
              <label for="take-from-resource">Take Worker From Resource:</label>
              <select id="take-from-resource" phx-change="take_worker_from_resource">
                <option value="" disabled selected>Choose a resource</option>
                <option value="wood">Wood</option>
                <option value="stone">Stone</option>
                <option value="iron">Iron</option>
              </select>
              <button phx-click="take_worker" phx-value-target="from">Go</button>
            </div>
          </div>

        <div class="game-field">
          <div class="base left-base">Player 1 Base</div>

          <div class="base right-base">Player 2 Base</div>

          <%= for unit <- @game_state.units do %>
            <div
              class={"unit #{unit.type}"}
              style={"left: #{unit.position.x}px; top: #{unit.position.y}px;"}
            >
              <%= unit.type %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("spawn_unit", %{"type" => type}, socket) do
    with {:ok, unit_type} <- validate_unit_type(type),
         player_id when not is_nil(player_id) <- socket.assigns.player_id,
         :ok <- Game.spawn_unit(socket.assigns.lobby_id, unit_type, player_id) do
      {:noreply, socket}
    else
      nil -> {:noreply, put_flash(socket, :error, "Player not assigned")}
      {:error, reason} -> {:noreply, put_flash(socket, :error, "Could not spawn unit: #{reason}")}
    end
  end

  @impl true
  def handle_event("take_worker", %{"target" => target_resource}, socket) do
    case Game.take_worker_from_resource(socket.assigns.lobby_id, String.to_atom(target_resource)) do
      {:ok, updated_game_state} ->
        {:noreply, assign(socket, :game_state, updated_game_state)}

      {:error, :insufficient_workers} ->
        {:noreply, put_flash(socket, :error, "No workers available in #{target_resource}!")}
    end
  end

  @impl true
  def handle_event("move_worker", %{"target" => target_resource}, socket) do
    case Game.move_worker_to_resource(socket.assigns.lobby_id, String.to_atom(target_resource)) do
      {:ok, updated_game_state} ->
        {:noreply, assign(socket, :game_state, updated_game_state)}

      {:error, :insufficient_workers} ->
        {:noreply, put_flash(socket, :error, "No unused workers available!")}
    end
  end

  @impl true
  def handle_info({:game_state_update, updated_game_state}, socket) do
    {:noreply, assign(socket, :game_state, updated_game_state)}
  end

  @impl true
  def handle_info(:start_countdown, socket) do
    countdown = @countdown_start
    send_countdown(self(), countdown)
    {:noreply, assign(socket, :countdown, countdown)}
  end

  @impl true
  def handle_info({:countdown, remaining}, socket) when remaining > 0 do
    send_countdown(self(), remaining - 1)
    {:noreply, assign(socket, :countdown, remaining)}
  end

  @impl true
  def handle_info({:countdown, 0}, socket) do
    {:noreply, assign(socket, :countdown, nil)}
  end

  defp send_countdown(pid, remaining) do
    Process.send_after(pid, {:countdown, remaining}, 1000)
  end

  defp validate_unit_type("archer"), do: {:ok, :archer}
  defp validate_unit_type("soldier"), do: {:ok, :soldier}
  defp validate_unit_type("cavalry"), do: {:ok, :cavalry}
  defp validate_unit_type(_), do: {:error, :invalid_unit_type}

  defp game_server_running?(lobby_id) do
    case :global.whereis_name({:game_server, lobby_id}) do
      :undefined -> false
      pid when is_pid(pid) -> Process.alive?(pid)
    end
  end
end
