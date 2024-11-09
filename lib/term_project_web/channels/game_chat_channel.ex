defmodule TermProjectWeb.GameChatChannel do
  use Phoenix.Channel

  def join("game:chat", payload, socket) do
    IO.inspect(payload, label: "Join payload")
    {:ok, socket}
  end

  def handle_in("send_msg", params, socket) do
    IO.inspect(params, label: "Received message")
    broadcast(socket, "receive_msg", params)
    {:noreply, socket}
  end
end
