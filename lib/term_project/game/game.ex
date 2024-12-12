defmodule TermProject.Game do
  use GenServer

  @tick_interval 100
  @game_channel "game:"
  @lobby_channel "lobby:"
  @field_width 1000
  @field_height 600

  def start_link(match_id) do
    GenServer.start_link(__MODULE__, %{match_id: match_id}, name: {:global, match_id})
  end

  def spawn_unit(match_id, unit_type, player_id) do
    GenServer.call({:global, match_id}, {:spawn_unit, unit_type, player_id})
  end

  def get_state(match_id) do
    GenServer.call({:global, match_id}, :get_state)
  end

  def init(%{match_id: match_id}) do
    initial_state = %{
      match_id: match_id,
      game_state: TermProject.GameState.new(),
      players: %{}
    }

    Phoenix.PubSub.subscribe(TermProject.PubSub, @game_channel <> "#{match_id}")
    Phoenix.PubSub.subscribe(TermProject.PubSub, @lobby_channel <> "#{match_id}")
    schedule_tick()

    {:ok, initial_state}
  end

  def handle_call({:spawn_unit, unit_type, player_id}, _from, state) do
    case TermProject.GameState.apply_action(state.game_state, {:create_unit, unit_type, player_id}) do
      {:ok, updated_game_state} ->
        broadcast_game_update(state.match_id, updated_game_state)
        {:reply, :ok, %{state | game_state: updated_game_state}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state.game_state, state}
  end

  def handle_info(:tick, state) do
    {updated_state, events} = state
    |> process_tick()

    broadcast_game_update(state.match_id, %{
      state: updated_state.game_state,
      events: events
    })

    schedule_tick()
    {:noreply, updated_state}
  end

  defp process_tick(state) do
    {state, events} = state
    |> increment_tick()
    |> then(fn state -> process_unit_movement(state) end)
    |> then(fn {state, events} -> process_combat(state, events) end)
    |> then(fn {state, events} -> update_resources(state, events) end)
    |> then(fn {state, events} -> check_victory_conditions(state, events) end)

    {state, events}
  end

  defp increment_tick(state) do
    {%{state | game_state: %{state.game_state | tick: state.game_state.tick + 1}}, []}
  end

  defp process_unit_movement(state) do
    updated_units = Enum.map(state.game_state.units, fn unit ->
      direction = if unit.owner == 1, do: 1, else: -1
      speed = get_unit_module(unit.type).stats().speed || 1
      new_x = min(max(0, unit.x + speed * direction), @field_width)
      %{unit | x: new_x}
    end)

    {%{state | game_state: %{state.game_state | units: updated_units}}, []}
  end

  defp process_combat(state, events) do
    {updated_units, combat_events} = TermProject.Game.CombatResolver.resolve(state.game_state.units)
    {%{state | game_state: %{state.game_state | units: updated_units}}, events ++ combat_events}
  end

  defp update_resources(state, events) do
    updated_resources = TermProject.ResourceManager.update_resources(
      state.game_state.resources,
      state.game_state.tick
    )
    {%{state | game_state: %{state.game_state | resources: updated_resources}}, events}
  end

  defp check_victory_conditions(state, events) do
    cond do
      state.game_state.bases[1].health <= 0 ->
        broadcast_game_over(state.match_id, %{winner: 2})
        {state, events ++ [{:game_over, %{winner: 2}}]}

      state.game_state.bases[2].health <= 0 ->
        broadcast_game_over(state.match_id, %{winner: 1})
        {state, events ++ [{:game_over, %{winner: 1}}]}

      true ->
        {state, events}
    end
  end

  defp broadcast_game_over(match_id, payload) do
    Phoenix.PubSub.broadcast(
      TermProject.PubSub,
      @game_channel <> "#{match_id}",
      {:game_over, payload}
    )
  end

  defp get_unit_module(:knight), do: TermProject.Units.Knight
  defp get_unit_module(:archer), do: TermProject.Units.Archer
  defp get_unit_module(:cavalry), do: TermProject.Units.Cavalry

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval)
  end

  defp broadcast_game_update(match_id, payload) do
    Phoenix.PubSub.broadcast(
      TermProject.PubSub,
      @game_channel <> "#{match_id}",
      {:game_state_update, payload}
    )
  end
end
