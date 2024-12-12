defmodule TermProjectWeb.LobbyRoomLive do
  use TermProjectWeb, :live_view

  def mount(%{"id" => lobby_id, "username" => username}, _session, socket) do
    lobby_id = String.to_integer(lobby_id)
    socket = assign(socket, username: username, messages: [], need_password: false)

    case TermProject.Game.LobbyServer.get_lobby(lobby_id) do
      {:ok, lobby} ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(TermProject.PubSub, "lobby:#{lobby_id}")
          Phoenix.PubSub.subscribe(TermProject.PubSub, "lobby:chat:#{lobby_id}")
        end

        result =
          cond do
            # User is already in the lobby
            Map.has_key?(lobby.players, username) ->
              {:ok, assign(socket, lobby: lobby, ready: false, messages: [], countdown: nil)}

            # Lobby requires a password
            Map.has_key?(lobby, :password) and lobby.password ->
              {:ok, assign(socket, need_password: true, lobby: lobby, countdown: nil)}

            # Lobby does not require a password
            true ->
              case TermProject.Game.LobbyServer.join_lobby(lobby_id, username) do
                :ok ->
                  # Fetch the updated lobby after joining
                  {:ok, updated_lobby} = TermProject.Game.LobbyServer.get_lobby(lobby_id)

                  {:ok,
                   assign(socket,
                     lobby: updated_lobby,
                     ready: false,
                     messages: [],
                     countdown: nil
                   )}

                {:error, :lobby_full} ->
                  {:ok,
                   socket
                   |> put_flash(:error, "Lobby is full")
                   |> redirect(to: ~p"/?username=#{socket.assigns.username}")}

                {:error, _} ->
                  {:ok,
                   socket
                   |> put_flash(:error, "Could not join lobby")
                   |> redirect(to: ~p"/?username=#{socket.assigns.username}")}
              end
          end

        result

      {:error, _} ->
        {:ok, redirect(socket, to: "/")}
    end
  end

  def handle_event("join_lobby", %{"username" => username}, socket) do
    lobby_id = socket.assigns.lobby.id

    case TermProject.Game.LobbyServer.join_lobby(lobby_id, username) do
      :ok ->
        {:noreply, assign(socket, username: username)}

      {:error, :lobby_full} ->
        {:noreply, put_flash(socket, :error, "Lobby is full")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not join lobby")}
    end
  end

  # handle event for submitting password
  def handle_event("submit_password", %{"password" => password}, socket) do
    lobby_id = socket.assigns.lobby.id
    username = socket.assigns.username

    case TermProject.Game.LobbyServer.join_lobby(lobby_id, username, password) do
      :ok ->
        # Fetch the updated lobby after joining
        {:ok, updated_lobby} = TermProject.Game.LobbyServer.get_lobby(lobby_id)
        {:noreply, assign(socket, need_password: false, lobby: updated_lobby, ready: false)}

      {:error, :incorrect_password} ->
        {:noreply, put_flash(socket, :error, "Incorrect password")}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not join lobby: #{inspect(reason)}")
         |> redirect(to: "/")}
    end
  end

  def handle_event("toggle_ready", _params, socket) do
    lobby_id = socket.assigns.lobby.id
    username = socket.assigns.username
    ready = !socket.assigns.ready

    case TermProject.Game.LobbyServer.set_ready_status(lobby_id, username, ready) do
      :ok ->
        {:noreply, assign(socket, ready: ready)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update ready status")}
    end
  end

  # Add close_lobby handler
  def handle_event("close_lobby", _params, socket) do
    lobby_id = socket.assigns.lobby.id
    username = socket.assigns.username

    case TermProject.Game.LobbyServer.close_lobby(lobby_id, username) do
      :ok ->
        {:noreply, push_navigate(socket, to: ~p"/?username=#{socket.assigns.username}")}

      {:error, :not_host} ->
        {:noreply, put_flash(socket, :error, "Only the host can close the lobby")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not close lobby")}
    end
  end

  def handle_event("send_message", %{"message" => msg}, socket) do
    user = socket.assigns.username || "Anonymous"
    message = %{user: user, body: msg}
    Phoenix.PubSub.broadcast(TermProject.PubSub, "lobby:chat:#{socket.assigns.lobby.id}", message)
    {:noreply, socket}
  end

  # Fix handle_info for lobby_updated message
  def handle_info(:lobby_updated, %{assigns: %{lobby: %{id: id}}} = socket) do
    case TermProject.Game.LobbyServer.get_lobby(id) do
      {:ok, updated_lobby} ->
        {:noreply, assign(socket, lobby: updated_lobby)}

      {:error, _} ->
        {:noreply, push_navigate(socket, to: ~p"/")}
    end
  end

  # Add handler for lobby_closed message
  def handle_info(:lobby_closed, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Lobby was closed by the host")
     |> push_navigate(to: ~p"/?username=#{socket.assigns.username}")}
  end

  def handle_info(%{body: body, user: user}, socket) do
    message = %{user: user, body: body}
    messages = [message | socket.assigns.messages]
    {:noreply, assign(socket, messages: messages)}
  end

  def handle_info(:start_countdown, socket) do
    send(self(), {:countdown, 15})
    {:noreply, assign(socket, countdown: 15)}
  end

  def handle_info({:countdown, 0}, socket) do
    # Navigate to the game page
    {:noreply,
     push_navigate(socket,
       to: ~p"/game/#{socket.assigns.lobby.id}?username=#{URI.encode(socket.assigns.username)}"
     )}
  end

  def handle_info({:countdown, seconds}, socket) do
    Process.send_after(self(), {:countdown, seconds - 1}, 1000)
    {:noreply, assign(socket, countdown: seconds - 1)}
  end
end
