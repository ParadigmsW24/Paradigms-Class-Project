defmodule TermProjectWeb.GameChannel do
  @moduledoc """
  Handles communication between the server and clients.
  """

  use Phoenix.Channel

  alias TermProject.Game

  def join("game:lobby", _message, socket) do
    player_id = assign_player_id(socket)
    {:ok, %{player_id: player_id}, assign(socket, :player_id, player_id)}
  end

  def handle_in("spawn_unit", %{"unit_type" => unit_type}, socket) do
    player_id = socket.assigns.player_id
    case Game.spawn_unit(player_id, String.to_existing_atom(unit_type)) do
      :ok ->
        # Broadcast sound_effect event to all clients in the "game:lobby" topic
        broadcast!(socket, "sound_effect", %{
          event: "unit_creation",
          data: %{unit_type: unit_type}
        })

        {:noreply, socket}

      {:error, reason} ->
        {:reply, {:error, reason}, socket}
    end
  end

  # TODO: Handle other incoming messages (e.g., resource management, chat messages)

  # Helper function to assign player IDs
  defp assign_player_id(socket) do
    # TODO: Implement proper player identification and authentication
    :erlang.phash2(socket.transport_pid)
  end
end
