defmodule TermProject.ResourceManager do
  @moduledoc """
  Handles resource accumulation, spending, and validation.

  Uses a worker pool system to dynamically adjust resource generation rates.

  Responsibilities:
  - Manages resource amounts and worker distribution.
  - Calculates resource generation rates based on worker allocation.
  - Supports adding, deducting, and redistributing workers.
  - Automates resource generation with conditional updates.
  - Validates resource availability for purchases and upgrades.
  """

  @default_worker_count 9
  @minimum_workers 0
  @default_wood_rate 60
  @default_stone_rate 30
  @default_iron_rate 15

  @type resources :: %{
    amounts: %{wood: integer(), stone: integer(), iron: integer()},
    workers: %{wood: integer(), stone: integer(), iron: integer(), unused: integer()}
  }

  @doc """
  Initializes resources with default amounts and evenly distributed workers.
  """
  def initialize() do
    workers_per_resource = div(@default_worker_count, 3)

    %{
      amounts: %{wood: 2000, stone: 2000, iron: 2000},
      workers: %{
        wood: workers_per_resource,
        stone: workers_per_resource,
        iron: workers_per_resource,
        unused: 0
      }
    }
  end

  @doc """
  Redistributes a worker from one resource to another.

  Parameters:
    - resources (map): The current resource map.
    - from_resource (atom): The resource key to remove a worker from.
    - to_resource (atom): The resource key to assign a worker to.

  Returns:
    - {:ok, updated_resources} if redistribution is successful.
    - {:error, :insufficient_workers} if there are no workers available to redistribute from the specified resource.
  """
  def redistribute_worker(resources, from_resource, to_resource) do
    from_workers = Map.get(resources.workers, from_resource, 0)

    if from_workers > @minimum_workers do
      updated_workers =
        resources.workers
        |> Map.update!(from_resource, &(&1 - 1))
        |> Map.update!(to_resource, &(&1 + 1))

      {:ok, %{resources | workers: updated_workers}}
    else
      {:error, :insufficient_workers}
    end
  end

  @doc """
  Adds 3 workers to the unused pool.

  Parameters:
    - resources (map): The current resource map.

  Returns: updated resource map with 3 additional workers in the `:unused` pool.
  """
  def add_workers_to_pool(resources) do
    updated_workers =
      Map.update!(resources.workers, :unused, &(&1 + 3))

    %{resources | workers: updated_workers}
  end

  @doc """
  Calculates the generation rate for each resource based on the number of assigned workers.

  Parameters:
    - resources (map): The current resource map.

  Returns: A map with rates for each resource, calculated relative to the default number of workers.
  """
  def calculate_rates(resources) do
    workers = resources.workers

    %{
      wood: Float.round(workers.wood * @default_wood_rate / 3, 2),
      stone: Float.round(workers.stone * @default_stone_rate / 3, 2),
      iron: Float.round(workers.iron * @default_iron_rate / 3, 2)
    }
  end

  @doc """
  Automatically updates resources based on current worker distribution and conditional flags.

  Parameters:
    - resources (map): The current resource map.
    - update_wood (boolean, optional): Whether to update wood resources.
    - update_stone (boolean, optional): Whether to update stone resources.
    - update_iron (boolean, optional): Whether to update iron resources.

  Returns: updated resource map with adjusted `amounts` for selected resources.
  """
  def auto_update(
    resources,
    update_wood \\ false,
    update_stone \\ false,
    update_iron \\ false
  ) do
    rates = calculate_rates(resources)

    additions = %{
    wood: if(update_wood, do: round(rates.wood), else: 0),
    stone: if(update_stone, do: round(rates.stone), else: 0),
    iron: if(update_iron, do: round(rates.iron), else: 0)
    }

    add(resources, additions)
  end

  @doc """
  Adds resources to the `:amount` field of each resource.

  Parameters:
    - resources (map): The current resource map.
    - additions (map): A map specifying the amounts to add for each resource.

  Returns: updated resource map with modified `:amounts`.
  """
  def add(resources, additions \\ %{}) do
    updated_amounts =
      Enum.reduce(additions, resources.amounts, fn {key, addition}, acc ->
        Map.update!(acc, key, &(&1 + addition))
      end)

    %{resources | amounts: updated_amounts}
  end

  @doc """
  Deducts resources. Validates whether a purchase or action is valid.

  Parameters:
    - resources (map): The current resource map.
    - costs (map): A map specifying the amounts to deduct for each resource.

  Returns:
    - {:ok, updated_resources} if the deduction is successful.
    - {:error, :insufficient_resources} if there are not enough resources to deduct.
  """
  def deduct(resources, costs \\ %{}) do
    if Enum.all?(costs, fn {key, value} -> Map.get(resources.amounts, key, 0) >= value end) do
      updated_amounts =
        Enum.reduce(costs, resources.amounts, fn {key, value}, acc ->
          Map.update!(acc, key, &(&1 - value))
        end)

      {:ok, %{resources | amounts: updated_amounts}}
    else
      {:error, :insufficient_resources}
    end
  end
end
