defmodule TermProject.Units.Archer do
  @behaviour TermProject.Unit

  @type t :: %__MODULE__{
          type: atom(),
          health: integer(),
          damage: integer(),
          range: integer(),
          owner: atom()
        }

  defstruct type: :archer, health: 50, damage: 10, range: 5, owner: nil

  @impl true
  def type, do: :archer

  @impl true
  def stats do
    %{
      type: :archer,
      health: 50,
      damage: 10,
      range: 5,
      position: %{x: 50, y: 250}
    }
  end

  @impl true
  def attack(%{owner: owner} = target, %{owner: attacker_owner} = attacker) when owner != attacker_owner do
    # Reduce target's health by the Archer's damage
    %{target | health: target.health - attacker.damage}
  end

  @impl true
  def in_range?({x1, _y1}, {x2, _y2}) do
    abs(x2 - x1) <= 5
  end
end
