defmodule TermProject.Server.GameServerTest do
  use ExUnit.Case, async: false

  setup_all do
    Application.ensure_all_started(:term_project)
    :ok
  end

  setup do
    :ets.delete_all_objects(:game_table)
    :ok
  end

  test "creates a new public lobby and adds a user" do
    username = "player1"

    # Make a request to join a public lobby (no password)
    assert {:ok, {lobby_id, lobby_state}} = TermProject.Server.GameServer.request_lobby(username, "")

    # The returned lobby should have one player
    assert lobby_state.players == [username]
    assert lobby_state.type == :public
    assert lobby_state.status == :waiting

    # Ensure it actually got inserted into the ETS table
    case :ets.lookup(:game_table, lobby_id) do
      [{^lobby_id, stored_lobby}] ->
        assert stored_lobby.players == [username]
      _ ->
        flunk("Lobby was not found in ETS after creation")
    end
  end

  test "joining a second user to a public lobby" do
    username1 = "player1"
    username2 = "player2"

    # First user requests a public lobby
    {:ok, {lobby_id, lobby_state}} = TermProject.Server.GameServer.request_lobby(username1, "")
    assert lobby_state.players == [username1]
    assert lobby_state.status == :waiting

    # Second user requests a public lobby, should join the same one if available
    {:ok, {same_lobby_id, updated_lobby_state}} = TermProject.Server.GameServer.request_lobby(username2, "")

    # It should be the same lobby_id as the first user
    assert same_lobby_id == lobby_id

    # Now the lobby should have two players and be ready
    assert Enum.sort(updated_lobby_state.players) == Enum.sort([username1, username2])
    assert updated_lobby_state.status == :ready
  end

  test "creates a new private lobby with a password" do
    username = "player1"
    password = "secret123"

    {:ok, {lobby_id, lobby_state}} = TermProject.Server.GameServer.request_lobby(username, password)

    # lobby_id should be the same as password for private lobbies
    assert lobby_id == password
    assert lobby_state.players == [username]
    assert lobby_state.type == :private
    assert lobby_state.status == :waiting

    # Check ETS directly
    case :ets.lookup(:game_table, lobby_id) do
      [{^lobby_id, stored_lobby}] ->
        assert stored_lobby.players == [username]
        assert stored_lobby.type == :private
      _ ->
        flunk("Private lobby not found in ETS after creation")
    end
  end

  test "joining a second user to an existing private lobby" do
    username1 = "player1"
    username2 = "player2"
    password = "secret123"

    # Create a private lobby
    {:ok, {lobby_id, lobby_state}} = TermProject.Server.GameServer.request_lobby(username1, password)
    assert lobby_id == password
    assert lobby_state.players == [username1]
    assert lobby_state.status == :waiting

    # Second user joins the same private lobby by password
    {:ok, {^lobby_id, updated_lobby_state}} = TermProject.Server.GameServer.request_lobby(username2, password)
    # Now it should have two players and be ready
    assert Enum.sort(updated_lobby_state.players) == Enum.sort([username1, username2])
    assert updated_lobby_state.status == :ready
  end

  test "error returned if private lobby is full" do
    username1 = "player1"
    username2 = "player2"
    username3 = "player3"
    password = "secret123"

    {:ok, {lobby_id, _lobby_state}} = TermProject.Server.GameServer.request_lobby(username1, password)
    {:ok, {^lobby_id, _}} = TermProject.Server.GameServer.request_lobby(username2, password)
    # Lobby now full (2 players), third user tries to join
    assert {:error, :lobby_full} = TermProject.Server.GameServer.request_lobby(username3, password)
  end
end
