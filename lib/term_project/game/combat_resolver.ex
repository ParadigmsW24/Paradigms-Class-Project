defmodule TermProject.Game.CombatResolver do
  @moduledoc """
  Handles combat interactions between units.
  """

  alias TermProject.Utils.Position
  alias TermProject.Game.Unit

  def resolve(units) do
    units
    |> Enum.reduce([], fn unit, acc ->
      case find_enemy_in_range(unit, units) do
        nil -> [unit | acc]
        enemy ->
          {updated_unit, updated_enemy} = engage_combat(unit, enemy)
          [updated_unit, updated_enemy | acc]
      end
    end)
    |> Enum.uniq_by(& &1.id)
  end

  defp find_enemy_in_range(unit, units) do
    Enum.find(units, fn other_unit ->
      other_unit.owner != unit.owner and
        in_range?(unit, other_unit)
    end)
  end

  defp in_range?(unit, target) do
    with {:ok, unit_module} <- get_unit_module(unit.type) do
      unit_module.in_range?({unit.x, unit.y}, {target.x, target.y})
    else
      _ -> false
    end
  end

  defp engage_combat(unit, target) do
    with {:ok, unit_module} <- get_unit_module(unit.type) do
      updated_target = unit_module.attack(target, unit)
      {unit, updated_target}
    else
      _ -> {unit, target}
    end
  end

  defp get_unit_module(unit_type) do
    case unit_type do
      :archer -> {:ok, TermProject.Game.UnitTypes.Archer}
      :cavalry -> {:ok, TermProject.Game.UnitTypes.Cavalry}
      :knight -> {:ok, TermProject.Game.UnitTypes.Knight}
      # TODO: Add other unit types here
      _ -> :error
    end
  end
end
