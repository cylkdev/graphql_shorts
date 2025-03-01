defmodule GraphQLShorts.TopLevelError do
  @moduledoc """
  TopLevel Error API.
  """
  alias GraphQLShorts.Serializer

  @type t :: %__MODULE__{
          code: atom() | binary(),
          message: binary()
        }

  @enforce_keys [:code, :message]

  defstruct @enforce_keys ++ [extensions: %{}]

  @doc """
  Returns a struct.

  ### Examples

      iex> GraphQLShorts.TopLevelError.create(code: :not_found, message: "no records found", extensions: %{documentation: "http://api.docs.com"})
      %GraphQLShorts.TopLevelError{
        code: :not_found,
        message: "no records found",
        extensions: %{documentation: "http://api.docs.com"}
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
      ...>   code: :not_found,
      ...>   message: "no records found",
      ...>   extensions: %{
      ...>     documentation: "http://api.docs.com"
      ...>   }
      ...> }
      ...> |> GraphQLShorts.TopLevelError.create()
      ...> |> GraphQLShorts.TopLevelError.to_json()
  """
  @spec to_json(data :: t() | map()) :: {:ok, map()} | {:error, term()}
  @spec to_json(data :: t() | map(), opts :: keyword()) :: {:ok, map()} | {:error, term()}
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

      iex> GraphQLShorts.TopLevelError.to_jsonable_map(%GraphQLShorts.TopLevelError{
      ...>   code: :not_found,
      ...>   message: "no records found",
      ...>   extensions: %{
      ...>     documentation: "http://api.docs.com",
      ...>     request_id: "request_id",
      ...>     timestamp: "timestamp"
      ...>   }
      ...> })
      %{
        message: "no records found",
        extensions: %{
          code: "NOT_FOUND",
          timestamp: "timestamp",
          request_id: "request_id",
          documentation: "http://api.docs.com"
        }
      }
  """
  @spec to_jsonable_map(data :: t() | map()) :: map()
  @spec to_jsonable_map(data :: t() | map(), opts :: keyword()) :: map()
  def to_jsonable_map(%{code: code, message: message} = data, _opts \\ []) do
    data = if is_struct(data), do: Map.from_struct(data), else: data

    exts = Serializer.to_jsonable_map(data[:extensions] || %{})

    exts =
      %{
        request_id: Logger.metadata()[:request_id],
        timestamp: DateTime.to_string(DateTime.utc_now())
      }
      |> Map.merge(exts)
      |> Map.put(:code, code |> to_string() |> String.upcase())

    %{
      message: message,
      extensions: exts
    }
  end
end
