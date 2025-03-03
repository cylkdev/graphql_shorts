if Code.ensure_loaded?(Ecto) do
  defmodule GraphQLShorts.CommonChangeset do
    @moduledoc """
    `GraphQLShorts.CommonChangeset` maps changeset errors
    to user input based on a keyword-list schema.
    """
    alias GraphQLShorts.UserError

    @doc false
    @spec errors_on_changeset(changeset :: Ecto.Changeset.t()) :: map()
    def errors_on_changeset(changeset) do
      Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
        Regex.replace(~r"%{(\w+)}", message, fn _, key ->
          key = String.to_existing_atom(key)
          opts |> Keyword.get(key, key) |> to_string()
        end)
      end)
    end

    @doc """
    Converts any changeset error that exists in the arguments
    to a `GraphQLShorts.UserError` struct based on the schema.

    ### Examples

        iex> GraphQLShorts.CommonChangeset.translate_changeset_errors(
        ...>   %{
        ...>     title: ["can't be blank"],
        ...>     comments: [
        ...>       %{body: ["can't be blank"]}
        ...>     ]
        ...>   },
        ...>   %{
        ...>     title: "",
        ...>     comments: [
        ...>       %{body: ""}
        ...>     ]
        ...>   },
        ...>   keys: [:title, :comments]
        ...> )
        [
          %GraphQLShorts.UserError{
            message: "can't be blank",
            field: [:input, :title]
          }
        ]
    """
    def translate_changeset_errors(changeset, input, definition, opts \\ [])

    def translate_changeset_errors(changesets, input, definition, opts)
        when is_list(changesets) do
      Enum.flat_map(changesets, &translate_changeset_errors(&1, input, definition, opts))
    end

    def translate_changeset_errors(changeset, input, definition, opts)
        when is_struct(changeset, Ecto.Changeset) do
      changeset
      |> errors_on_changeset()
      |> translate_changeset_errors(input, definition, opts)
    end

    def translate_changeset_errors(errors, input, definition, _opts) do
      errors
      |> Map.to_list()
      |> recurse_build(input, definition[:keys] || [], [:input], [])
      |> Enum.reverse()
    end

    defp recurse_build([], _input, _schema_keys, _path, acc) do
      acc
    end

    defp recurse_build([head | tail], input, schema_keys, path, acc) do
      with acc <- recurse_build(head, input, schema_keys, path, acc) do
        recurse_build(tail, input, schema_keys, path, acc)
      end
    end

    defp recurse_build({_error_key, [] = _errors}, _input, _schema_keys, _path, acc) do
      acc
    end

    defp recurse_build({error_key, [head | tail]}, input, schema_keys, path, acc) do
      with acc <- recurse_build({error_key, head}, input, schema_keys, path, acc) do
        recurse_build({error_key, tail}, input, schema_keys, path, acc)
      end
    end

    defp recurse_build({error_key, errors}, input, schema_keys, path, acc) when is_map(errors) do
      case find_definition(schema_keys, error_key) do
        {:error, :not_found} ->
          acc

        {:ok, definition} ->
          definition = definition || []

          input_key = definition[:input_key] || error_key

          if Map.has_key?(input, input_key) do
            input = Map.fetch!(input, input_key)

            schema_keys = definition[:keys] || []

            errors
            |> Map.to_list()
            |> recurse_build(input, schema_keys, [input_key | path], acc)
          else
            acc
          end
      end
    end

    defp recurse_build({error_key, message}, input, schema_keys, path, acc)
         when is_binary(message) do
      case find_definition(schema_keys, error_key) do
        {:error, :not_found} ->
          acc

        {:ok, definition} ->
          definition = definition || []

          input_key = definition[:input_key] || error_key

          input
          |> List.wrap()
          |> Enum.reduce(acc, &reduce_user_error(message, &1, input_key, definition, path, &2))
      end
    end

    defp reduce_user_error(message, input, input_key, definition, path, acc) do
      if Map.has_key?(input, input_key) do
        params = %{
          message: message,
          field: Enum.reverse([input_key | path])
        }

        resolution = resolve(params, definition)

        user_error =
          UserError.create(
            message: resolution[:message] || params.message,
            field: resolution[:field] || params.field
          )

        [user_error | acc]
      else
        acc
      end
    end

    defp find_definition(list, key) do
      res =
        Enum.find(list, fn
          ^key -> true
          {^key, _} -> true
          _ -> false
        end)

      case res do
        {^key, definition} -> {:ok, definition}
        ^key -> {:ok, []}
        nil -> {:error, :not_found}
      end
    end

    defp resolve(params, definition) do
      case definition[:resolve] do
        nil -> %{}
        fun -> fun.(params)
      end
    end
  end
end
