defmodule GraphQLShorts.Utils do
  @moduledoc """
  ...
  """

  @doc """
  Deeply transform key value pairs from maps to apply operations on nested maps

  ### Example

      iex> GraphQLShorts.Utils.deep_transform(%{"test" => %{"item" => 2, "d" => 3}}, fn {k, v} ->
      ...>   if k === "d" do
      ...>     :delete
      ...>   else
      ...>     {String.to_atom(k), v}
      ...>   end
      ...> end)
      %{test: %{item: 2}}
  """
  def deep_transform(map, transform_fn) when is_map(map) do
    Enum.reduce(map, %{}, fn {k, v}, acc ->
      case transform_fn.({k, v}) do
        {k, v} -> Map.put(acc, k, deep_transform(v, transform_fn))
        :delete -> acc
      end
    end)
  end

  def deep_transform(list, transform_fn) when is_list(list) do
    Enum.map(list, &deep_transform(&1, transform_fn))
  end

  def deep_transform(value, _), do: value
end
