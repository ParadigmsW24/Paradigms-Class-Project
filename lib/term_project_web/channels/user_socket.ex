defmodule TermProjectWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "game:chat", TermProjectWeb.GameChatChannel # Add game chat channel
  channel "game:*", TermProjectWeb.GameChannel


  # TODO: Implement authentication if required
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
