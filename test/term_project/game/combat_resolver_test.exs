defmodule TermProject.Game.CombatResolverTest do
  use ExUnit.Case

  alias TermProject.Game.CombatResolver

  setup do
    units = [
      %{id: "1", type: :knight, owner: 1, health: 100, damage: 20, x: 0, y: 0},
      %{id: "2", type: :archer, owner: 2, health: 50, damage: 10, x: 4, y: 0}
    ]
    {:ok, %{units: units}}
  end

  test "resolves combat between units in range", %{units: units} do
    {updated_units, events} = CombatResolver.resolve(units)

    assert length(events) > 0
    [combat_event | _] = events
    assert combat_event.attacker == "1"
    assert combat_event.target == "2"

    [unit1, unit2] = updated_units
    assert unit2.health < 50 # Took damage
  end
end
