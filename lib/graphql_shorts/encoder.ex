defmodule GraphQLShorts.Encoder do
  @moduledoc """
  JSON Encoder API
  """

  @doc """
  Encodes the `term` to JSON.

  ### Examples

      iex> GraphQLShorts.Encoder.to_json([:some_name])
      ["someName"]

      iex> GraphQLShorts.Encoder.to_json(["some_name"])
      ["someName"]
  """
  @spec to_json(term()) :: term()
  @spec to_json(term(), opts :: keyword()) :: term()
  def to_json(list, opts \\ [])

  def to_json(list, opts) when is_list(list) do
    Enum.map(list, &to_json(&1, opts))
  end

  def to_json(str, _opts) when is_binary(str) do
    ProperCase.camel_case(str, :lower)
  end

  def to_json(term, _opts) when is_atom(term) do
    term
    |> Atom.to_string()
    |> ProperCase.camel_case(:lower)
  end

  def to_json(data, opts) when is_map(data) do
    data
    |> adapter!(opts).encode!(opts)
    |> GraphQLShorts.Utils.deep_transform(fn {key, val} ->
      {key |> to_string() |> ProperCase.camel_case(:lower), val}
    end)
  end

  def to_json(term, opts) do
    adapter!(opts).encode!(term, opts)
  end

  defp adapter!(opts) do
    opts[:json_adapter] || GraphQLShorts.Config.json_adapter() || Jason
  end
end
