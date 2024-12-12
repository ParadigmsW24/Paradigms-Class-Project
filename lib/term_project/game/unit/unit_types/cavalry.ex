defmodule TermProject.Units.Cavalry do
  @behaviour TermProject.Unit

  @type t :: %__MODULE__{
          type: atom(),
          health: integer(),
          damage: integer(),
          range: integer(),
          speed: integer(),
          owner: atom()
        }

  defstruct type: :cavalry, health: 75, damage: 15, range: 2, speed: 3, owner: nil

  @impl true
  def type, do: :cavalry

  @impl true
  def stats(owner) do
    %{
      type: :cavalry,
      health: 75,
      damage: 15,
      range: 2,
      speed: 3,
      position: %{x: 50, y: 250},
      owner: owner
    }
  end

  @impl true
  def attack(%{owner: owner} = target, %{owner: attacker_owner} = attacker) when owner != attacker_owner do
    # Reduce target's health by the Cavalry's damage
    %{target | health: target.health - attacker.damage}
  end

  @impl true
  def in_range?({x1, _y1}, {x2, _y2}) do
    abs(x2 - x1) <= 2
  end
end
