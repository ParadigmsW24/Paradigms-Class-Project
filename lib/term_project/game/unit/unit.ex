defmodule TermProject.Unit do
  @moduledoc """
  Behaviour for defining units in the game.
  """

  @callback type() :: atom()
  @callback stats() :: %{health: integer(), damage: integer(), range: integer()}
  @callback attack(target :: map(), attacker :: map()) :: map()
  @callback in_range?(unit_position :: {integer(), integer()}, target_position :: {integer(), integer()}) :: boolean()
end
