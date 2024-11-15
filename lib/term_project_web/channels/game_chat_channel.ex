defmodule TermProjectWeb.GameChatChannel do
  use Phoenix.Channel

  def join("game:chat", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("send_msg", %{"message" => message}, socket) do
    broadcast(socket, "new_msg", %{message: message})
    {:noreply, socket}
  end

  def handle_in(_event, _payload, socket) do
    {:noreply, socket}
  end
end
