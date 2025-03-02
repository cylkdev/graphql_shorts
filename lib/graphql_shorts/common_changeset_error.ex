if Code.ensure_loaded?(Ecto) do
  defmodule GraphQLShorts.CommonChangesetError do
    @moduledoc """
    `GraphQLShorts.CommonChangesetError` maps changeset errors
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
    Converts any changeset error that exists in the arguments to a
    `GraphQLShorts.UserError` struct based on the schema.
    """
    def translate_changeset_errors(changeset, input, schema_opts, opts \\ [])

    def translate_changeset_errors(changeset, input, schema_opts, opts)
        when is_struct(changeset, Ecto.Changeset) do
      changeset
      |> errors_on_changeset()
      |> translate_changeset_errors(input, schema_opts, opts)
    end

    def translate_changeset_errors(errors, input, schema_opts, _opts) do
      errors
      |> Map.to_list()
      |> recurse_build(input, schema_opts[:keys] || [], [:input], [])
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
      case find_schema_opts(schema_keys, error_key) do
        {:error, :not_found} ->
          acc

        {:ok, schema_opts} ->
          schema_opts = schema_opts || []

          input_key = schema_opts[:input_key] || error_key

          if Map.has_key?(input, input_key) do
            input = Map.fetch!(input, input_key)

            schema_keys = schema_opts[:keys] || []

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
      case find_schema_opts(schema_keys, error_key) do
        {:error, :not_found} ->
          acc

        {:ok, schema_opts} ->
          schema_opts = schema_opts || []

          input_key = schema_opts[:input_key] || error_key

          input
          |> List.wrap()
          |> Enum.reduce(acc, fn input, acc ->
            if Map.has_key?(input, input_key) do
              field = Enum.reverse([input_key | path])

              message = resolve(message, schema_opts)

              user_error = UserError.create(message: message, field: field)

              [user_error | acc]
            else
              acc
            end
          end)
      end
    end

    defp find_schema_opts(list, key) do
      res =
        Enum.find(list, fn
          ^key -> true
          {^key, _} -> true
          _ -> false
        end)

      case res do
        {^key, schema_opts} -> {:ok, schema_opts}
        ^key -> {:ok, []}
        nil -> {:error, :not_found}
      end
    end

    defp resolve(message, schema_opts) do
      case schema_opts[:resolve] do
        nil ->
          message

        fun ->
          case fun.(message) do
            message when is_binary(message) -> message
            term -> raise "Expected a string, got: #{inspect(term)}"
          end
      end
    end
  end
end
