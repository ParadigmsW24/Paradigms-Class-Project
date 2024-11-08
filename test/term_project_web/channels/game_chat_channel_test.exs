defmodule TermProjectWeb.GameChatChannelTest do
  use TermProjectWeb.ChannelCase

  alias TermProjectWeb.GameChatChannel

  setup do
    {:ok, socket} = connect(UserSocket, %{})
    {:ok, socket: socket}
  end

  test "joins the game:chat topic", %{socket: socket} do
    assert {:ok, _, _socket} = subscribe_and_join(socket, GameChatChannel, "game:chat")
  end

  test "broadcasts new messages", %{socket: socket} do
    {:ok, _, socket} = subscribe_and_join(socket, GameChatChannel, "game:chat")
    ref = push(socket, "send_msg", %{"message" => "hello"})

    assert_reply ref, :noreply, socket

    assert_broadcast "receive_msg", %{"message" => "hello"}
    assert_no_broadcast "error"
  end
end
