defmodule TermProject.Units.Soldier do
  @behaviour TermProject.Unit

  @type t :: %__MODULE__{
          type: atom(),
          health: integer(),
          damage: integer(),
          range: integer(),
          owner: atom()
        }

  defstruct type: :soldier, health: 100, damage: 20, range: 1, owner: nil

  @impl true
  def type, do: :soldier

  @impl true
  def stats do
    %{
      health: 100,
      damage: 20,
      range: 1
    }
  end

  @impl true
  def attack(%{owner: owner} = target, %{owner: attacker_owner} = attacker) when owner != attacker_owner do
    %{target | health: target.health - attacker.damage}
  end

  @impl true
  def in_range?({x1, _y1}, {x2, _y2}) do
    abs(x2 - x1) <= 1
  end
end
