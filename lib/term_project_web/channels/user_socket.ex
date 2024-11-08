defmodule TermProjectWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "game:*", TermProjectWeb.GameChannel
  channel "game:chat", TermProjectWeb.GameChatChannel # Add game chat channel

  # Transports
  transport :websocket, Phoenix.Transports.WebSocket,
    serializer: [{Phoenix.Socket.V2.JSONSerializer, "~> 2.0.0"}],
    timeout: 45_000
  # TODO: Implement authentication if required
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
