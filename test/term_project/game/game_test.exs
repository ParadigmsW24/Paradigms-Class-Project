defmodule TermProject.GameTest do
  use ExUnit.Case

  alias TermProject.Game
  alias TermProject.GameState

  setup do
    match_id = "test_match"
    {:ok, _pid} = Game.start_link(match_id)
    {:ok, %{match_id: match_id}}
  end

  describe "game lifecycle" do
    test "spawns units and updates state", %{match_id: match_id} do
      # Test unit spawning
      :ok = Game.spawn_unit(match_id, :knight, 1)
      state = Game.get_state(match_id)
      assert length(state.units) == 1

      [unit] = state.units
      assert unit.type == :knight
      assert unit.owner == 1
    end

    test "handles combat between units", %{match_id: match_id} do
      # Spawn opposing units
      :ok = Game.spawn_unit(match_id, :knight, 1)
      :ok = Game.spawn_unit(match_id, :archer, 2)

      # Let combat resolve in tick
      Process.sleep(200)

      state = Game.get_state(match_id)
      [unit1, unit2] = state.units

      # Verify combat occurred
      assert unit1.health < 100 or unit2.health < 50
    end

    test "manages resources correctly", %{match_id: match_id} do
      initial_state = Game.get_state(match_id)
      initial_wood = initial_state.resources.amounts.wood

      # Spawn knight (costs 50 wood, 30 iron)
      :ok = Game.spawn_unit(match_id, :knight, 1)

      updated_state = Game.get_state(match_id)
      assert updated_state.resources.amounts.wood == initial_wood - 50
    end
  end
end
