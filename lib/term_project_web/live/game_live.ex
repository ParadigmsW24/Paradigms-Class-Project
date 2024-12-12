defmodule TermProjectWeb.GameLive do
  use TermProjectWeb, :live_view
  alias TermProject.Game

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to game updates
      Phoenix.PubSub.subscribe(TermProject.PubSub, "game")
      :timer.send_interval(100, self(), :tick)
      send(self(), :stop_background_music)
    end

    {:ok, assign(socket,
      player_id: 1,
      resources: 100,
      base_health: 1000,
      units: []
    )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="game-container">
      <div class="status-panel">
        <div class="resource-counter">Resources: <%= @resources %></div>
        <div class="base-health">Base Health: <%= @base_health %></div>
      </div>

      <div class="game-controls">
        <button phx-click="spawn_unit" phx-value-type="soldier" class="unit-button">
          Spawn Soldier (50)
        </button>
        <button phx-click="spawn_unit" phx-value-type="archer" class="unit-button">
          Spawn Archer (75)
        </button>
        <button phx-click="spawn_unit" phx-value-type="cavalry" class="unit-button">
          Spawn Cavalry (100)
        </button>
      </div>

      <div class="game-field">
        <div class="base left-base">Player 1 Base</div>
        <div class="base right-base">Player 2 Base</div>
        <%= for unit <- @units do %>
          <div class={"unit #{unit.type}"} style={"left: #{unit.position.x}px; top: #{unit.position.y}px;"}>
            <%= unit.type %>
          </div>
        <% end %>
      </div>
    </div>
        <script>
      document.addEventListener('DOMContentLoaded', () => {
        const soldierButton = document.querySelector('[phx-value-type="soldier"]');
        if (soldierButton) {
          soldierButton.addEventListener("click", () => {
            const audio = new Audio("/sounds/knight_spawn.mp3");
            audio.play()
              .then(() => console.log("Soldier sound played"))
              .catch((error) => console.error("Error playing soldier sound:", error));
          });
        }

        const archerButton = document.querySelector('[phx-value-type="archer"]');
        if (archerButton) {
          archerButton.addEventListener("click", () => {
            const audio = new Audio("/sounds/archer_spawn.mp3");
            audio.play()
              .then(() => console.log("Archer sound played"))
              .catch((error) => console.error("Error playing archer sound:", error));
          });
        }

        const cavalryButton = document.querySelector('[phx-value-type="cavalry"]');
        if (cavalryButton) {
          cavalryButton.addEventListener("click", () => {
            const audio = new Audio("/sounds/calvalry_spawn.wav");
            audio.play()
              .then(() => console.log("Cavalry sound played"))
              .catch((error) => console.error("Error playing cavalry sound:", error));
          });
        }

      // Stop background music (for game page only)
        const backgroundMusic = document.getElementById('background-music');
        if (backgroundMusic) {
          backgroundMusic.pause();  // Music will stop when the game page is loaded
          console.log("Background music stopped on game page");
        }
      });
    </script>
    """
  end

  @impl true
  def handle_event("spawn_unit", %{"type" => type}, socket) do
    unit_type = String.to_atom(type)
    # Create a simple unit for testing
    new_unit = %{
      id: System.unique_integer([:positive]),
      type: unit_type,
      position: %{x: 50, y: 250},  # Start position for player 1
      owner: socket.assigns.player_id,
      health: 100
    }

    new_units = [new_unit | socket.assigns.units]
    {:noreply, assign(socket, units: new_units)}
  end

  @impl true
  def handle_info(:stop_background_music, socket) do
    send(self(), {:stop_background_music_js})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:stop_background_music_js}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    # Move all units to the right
    updated_units = Enum.map(socket.assigns.units, fn unit ->
      new_x = unit.position.x + 5  # Move 5 pixels right each tick
      %{unit | position: %{unit.position | x: new_x}}
    end)

    # Remove units that are off screen
    remaining_units = Enum.filter(updated_units, fn unit ->
      unit.position.x < 1200  # Game container width
    end)

    {:noreply, assign(socket, units: remaining_units)}
  end
end
