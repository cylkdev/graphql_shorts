defmodule GraphQLShorts.Serializer do
  @moduledoc """
  # GraphQLShorts.Serializer

  This API is responsible for ensuring terms are converted to a format
  that can be represented as a JSON string.
  """

  @doc """
  Returns a map with values that can be serialized to a JSON string.

  ### Examples

      iex> GraphQLShorts.Serializer.to_jsonable_map(%{
      ...>   params: %{
      ...>     id: 1,
      ...>     tags: ["example"],
      ...>     inserted_at: ~U[2025-02-24 00:00:00Z]
      ...>   },
      ...>   query: MyApp.SchemaModule
      ...> })
      %{
        params: %{
          id: "1",
          tags: ["example"],
          inserted_at: "2025-02-24T00:00:00Z"
        },
        query: "MyApp.SchemaModule"
      }
  """
  @spec to_jsonable_map(term()) :: term()
  def to_jsonable_map(date) when is_struct(date, Date), do: Date.to_iso8601(date)

  def to_jsonable_map(time) when is_struct(time, Time), do: Time.to_iso8601(time)

  def to_jsonable_map(datetime) when is_struct(datetime, DateTime),
    do: DateTime.to_iso8601(datetime)

  def to_jsonable_map(datetime) when is_struct(datetime, NaiveDateTime),
    do: NaiveDateTime.to_iso8601(datetime)

  def to_jsonable_map(%struct{} = struct_data) do
    %{
      struct: atom_to_string(struct),
      data: struct_data |> Map.from_struct() |> to_jsonable_map()
    }
  end

  def to_jsonable_map(data) when is_map(data) do
    Map.new(data, fn {k, v} -> {k, to_jsonable_map(v)} end)
  end

  def to_jsonable_map(data) when is_list(data) do
    Enum.map(data, &to_jsonable_map/1)
  end

  def to_jsonable_map(data) when is_tuple(data) do
    data |> Tuple.to_list() |> to_jsonable_map()
  end

  def to_jsonable_map(atom) when is_atom(atom) do
    atom_to_string(atom)
  end

  def to_jsonable_map(value), do: to_string(value)

  defp atom_to_string(v) do
    v |> Atom.to_string() |> String.replace("Elixir.", "")
  end
end
