defmodule TermProjectWeb.GameLive do
  use TermProjectWeb, :live_view
  alias TermProject.Game

  @impl true
  def mount(params, _session, socket) do
    lobby_id = String.to_integer(params["id"])
    username = params["username"]

    socket =
      socket
      |> assign(:lobby_id, lobby_id)
      |> assign(:username, username)
      |> assign(:resources, %{wood: 0, stone: 0, iron: 0})
      |> assign(:units, [])
      |> assign(:bases, %{1 => %{health: 1000}, 2 => %{health: 1000}})

    if connected?(socket) do
      Phoenix.PubSub.subscribe(TermProject.PubSub, "game:#{lobby_id}")
      game_state = Game.get_state(lobby_id)
      socket = assign_game_state(socket, game_state)
    
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    IO.inspect(assigns, label: "Render Assigns")
    ~H"""
    <div class="game-container">
      <div class="status-panel">
        <div class="resource-counter">
          Resources:
          Wood: <%= @resources[:wood] || 0 %>,
          Stone: <%= @resources[:stone] || 0 %>,
          Iron: <%= @resources[:iron] || 0 %>
        </div>
        <div class="base-health">Base Health: <%= @bases[1].health %> (Yours)</div>
      </div>

      <div class="game-controls">
        <button phx-click="spawn_unit" phx-value-type="archer" class="unit-button">
          Spawn Archer
        </button>
        <button phx-click="spawn_unit" phx-value-type="knight" class="unit-button">
          Spawn Knight
        </button>
        <button phx-click="spawn_unit" phx-value-type="cavalry" class="unit-button">
          Spawn Cavalry
        </button>
      </div>

      <div class="game-field" style="position: relative; width: 1000px; height: 600px; border: 1px solid #000;">
        <div class="base left-base" style="position: absolute; left: 0; top: 300px;">Player 1 Base</div>
        <div class="base right-base" style="position: absolute; right: 0; top: 300px;">Player 2 Base</div>

        <%= for unit <- @units do %>
          <div class={"unit #{unit.type}"} style={"position:absolute; left:#{unit.position.x}px; top:#{unit.position.y}px;"}>
            <%= Atom.to_string(unit.type) %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("spawn_unit", %{"type" => type}, socket) do
    unit_type = String.to_atom(type)
    # Call the backend Game server to spawn unit
    Game.spawn_unit(socket.assigns.lobby_id, unit_type, socket.assigns.username)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:game_state_update, new_state}, socket) do
    # Update the LiveView assigns with the new state
    {:noreply, assign_game_state(socket, new_state)}
  end

  # Helper function to assign game_state fields into the socket
  defp assign_game_state(socket, game_state) do
    # Extract resources with safe defaults
    resources = Map.get(game_state, :resources, %{wood: 0, stone: 0, iron: 0})
    IO.inspect(resources, label: "Resources in assign_game_state") # Log resources

    socket
    |> assign(:units, Map.get(game_state, :units, []))
    |> assign(:resources, resources)
    |> assign(:bases, Map.get(game_state, :bases, %{1 => %{health: 1000}, 2 => %{health: 1000}}))
  end

end
