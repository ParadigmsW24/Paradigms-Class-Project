# FILE: lib/term_project/server/test_game_server.ex
defmodule TermProject.Server.GameServerTest do
  use ExUnit.Case, async: true

  alias TermProject.Server.GameServer

  setup do
    :ets.new(:game_table, [:named_table, :public, :set])
    {:ok, _pid} = GameServer.start_link(nil)
    :ok
  end

  test "request_lobby/2 creates a new private lobby if it doesn't exist" do
    username = "player1"
    password = "secret"

    assert {:ok, {^password, lobby}} = GameServer.request_lobby(username, password)
    assert lobby.type == :private
    assert lobby.players == [username]
    assert lobby.status == :waiting
  end

  test "request_lobby/2 joins an existing private lobby if there's room" do
    username1 = "player1"
    username2 = "player2"
    password = "secret"

    GameServer.request_lobby(username1, password)
    assert {:ok, {^password, lobby}} = GameServer.request_lobby(username2, password)
    assert lobby.players == [username2, username1]
    assert lobby.status == :ready
  end

  test "request_lobby/2 returns error if private lobby is full" do
    username1 = "player1"
    username2 = "player2"
    username3 = "player3"
    password = "secret"

    GameServer.request_lobby(username1, password)
    GameServer.request_lobby(username2, password)
    assert {:error, :lobby_full} = GameServer.request_lobby(username3, password)
  end

  test "request_lobby/2 creates a new public lobby if none exists" do
    username = "player1"

    assert {:ok, {lobby_id, lobby}} = GameServer.request_lobby(username, "")
    assert lobby.type == :public
    assert lobby.players == [username]
    assert lobby.status == :waiting
    assert lobby.id == lobby_id
  end

  test "request_lobby/2 joins an existing public lobby if there's room" do
    username1 = "player1"
    username2 = "player2"

    GameServer.request_lobby(username1, "")
    assert {:ok, {lobby_id, lobby}} = GameServer.request_lobby(username2, "")
    assert lobby.players == [username2, username1]
    assert lobby.status == :ready
    assert lobby.id == lobby_id
  end

  test "request_lobby/2 creates a new public lobby if existing ones are full" do
    username1 = "player1"
    username2 = "player2"
    username3 = "player3"

    GameServer.request_lobby(username1, "")
    GameServer.request_lobby(username2, "")
    assert {:ok, {new_lobby_id, new_lobby}} = GameServer.request_lobby(username3, "")
    assert new_lobby.type == :public
    assert new_lobby.players == [username3]
    assert new_lobby.status == :waiting
    assert new_lobby.id == new_lobby_id
  end
end
