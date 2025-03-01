defmodule GraphQLShorts.UserError do
  @moduledoc """
  User Error API.
  """

  @type t :: %__MODULE__{
          field: binary() | list(binary()),
          message: binary()
        }

  @enforce_keys [:field, :message]

  defstruct @enforce_keys

  @doc """
  Returns a struct.

  ### Examples

      iex> GraphQLShorts.UserError.create(message: "cannot be blank", field: ["input", "email"])
      %GraphQLShorts.UserError{
        field: ["input", "email"],
        message: "cannot be blank"
      }
  """
  @spec create(params :: map() | keyword()) :: t()
  def create(params) do
    struct!(__MODULE__, params)
  end

  @doc """
  Returns a JSON encoded map.

  ### Options

  See `GraphQLShorts.Encoder.to_json/2` for options.

  ### Examples

      iex> %{
      ...>   message: "cannot be blank",
      ...>   field: ["input", "email"]
      ...> }
      ...> |> GraphQLShorts.UserError.create()
      ...> |> GraphQLShorts.UserError.to_json()
  """
  @spec to_json(data :: term()) :: {:ok, map()} | {:error, term()}
  @spec to_json(data :: term(), opts :: keyword()) :: {:ok, map()} | {:error, term()}
  def to_json(data, opts \\ [])

  def to_json(data, opts) when is_list(data) do
    Enum.map(data, &to_json(&1, opts))
  end

  def to_json(data, opts) do
    data
    |> to_jsonable_map()
    |> GraphQLShorts.Encoder.to_json(opts)
  end

  @doc """
  Returns a map that can be safely encoded to JSON.

  ### Examples

      iex> GraphQLShorts.UserError.to_jsonable_map(%GraphQLShorts.UserError{
      ...>   field: ["input", "email"],
      ...>   message: "cannot be blank"
      ...> })
      %{message: "cannot be blank", field: ["input", "email"]}
  """
  @spec to_jsonable_map(data :: t() | map()) :: map()
  @spec to_jsonable_map(data :: t() | map(), opts :: keyword()) :: map()
  def to_jsonable_map(%{message: message, field: field} = _data, opts \\ []) do
    %{
      message: message,
      field: field |> List.wrap() |> encode_json_strings(opts)
    }
  end

  defp encode_json_strings(list, opts) do
    unless Enum.any?(list) and Enum.all?(list, &is_binary/1) do
      raise ArgumentError,
            "Expected field to be a string or a list of strings, got: #{inspect(list)}"
    end

    GraphQLShorts.Encoder.to_json(list, opts)
  end
end
