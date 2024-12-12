defmodule TermProject.Game.UnitTypes.Cavalry do
  @moduledoc """
  Cavalry unit implementation.
  """

  @behaviour TermProject.Game.Unit

  alias TermProject.Utils.Position

  @impl true
  def init(opts) do
    unit = %{
      id: opts[:id],
      type: :cavalry,
      position: opts[:position],
      owner: opts[:owner],
      health: 150,
      damage: 20,
      speed: 2.0,
      range: 1.5
    }

    # Notify that a new unit of type :cavalry has been created
    notify_sound_effect(:unit_creation, %{unit_type: unit.type, unit_id: unit.id})

    unit
  end

  @impl true
  def move(unit) do
    target_position = Position.enemy_base(unit.owner)
    new_position = Position.move_towards(unit.position, target_position, unit.speed)
    %{unit | position: new_position}
  end

  @impl true
  def attack(unit, target) do
    # Cavalry may have special attack logic
    new_target = %{target | health: target.health - unit.damage}
    {unit, new_target}
  end

  @impl true
  def in_range?(unit, target) do
    Position.distance(unit.position, target.position) <= unit.range
  end

  # Helper function to broadcast sound effect events.
  defp notify_sound_effect(event, data) do
    Phoenix.PubSub.broadcast(
      TermProject.PubSub,
      "sound_effects",
      %{event: event, data: data}
    )
  end
end
