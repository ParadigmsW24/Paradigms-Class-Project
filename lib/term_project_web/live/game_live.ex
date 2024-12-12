defmodule TermProjectWeb.GameLive do
  use TermProjectWeb, :live_view
  alias TermProject.Game

  @impl true
  def mount(%{"match_id" => match_id}, _session, socket) do
    if connected?(socket) do
      # Subscribe to game updates
      Phoenix.PubSub.subscribe(
        TermProject.PubSub,
        "game:#{match_id}"
      )
    end

    {:ok, assign(socket,
      match_id: match_id,
      game_state: TermProject.Game.get_state(match_id)
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
  def handle_info({:game_state_update, %{state: new_state, events: events}}, socket) do
    # Apply events and update state
    {:noreply, assign(socket,
      game_state: new_state
    )}
  end
end
