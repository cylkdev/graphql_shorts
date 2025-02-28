if Code.ensure_loaded?(Ecto) do
  defmodule GraphQLShorts.Bridges.ChangesetBridge do
    @moduledoc """
    `GraphQLShorts.Bridges.ChangesetBridge` provides an API that
    allows to you map changeset errors to arguments and converts them
    into user errors based on a schema.
    """
    alias GraphQLShorts.UserError

    @default_path [:input]

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
    @spec convert_to_error_message(
            changeset_or_map :: Ecto.Changeset.t() | map(),
            args :: map(),
            schema_opts :: map() | keyword()
          ) :: list(GraphQLShorts.UserError.t())
    @spec convert_to_error_message(
            changeset_or_map :: Ecto.Changeset.t() | map(),
            args :: map(),
            schema_opts :: map() | keyword(),
            opts :: keyword()
          ) :: list(GraphQLShorts.UserError.t())
    def convert_to_error_message(changeset, args, schema_opts, opts \\ [])

    def convert_to_error_message(changeset, args, schema_opts, opts)
        when is_struct(changeset, Ecto.Changeset) do
      changeset
      |> errors_on_changeset()
      |> convert_to_error_message(args, schema_opts, opts)
    end

    def convert_to_error_message(errors, args, schema_opts, _opts) do
      path = schema_opts[:path] || @default_path

      input = get_in(args, path) || %{}

      errors
      |> Map.to_list()
      |> recurse_build(input, schema_opts[:keys] || [], path, [])
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

        schema_opts ->
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

        schema_opts ->
          schema_opts = schema_opts || []

          input_key = schema_opts[:input_key] || error_key

          input
          |> List.wrap()
          |> Enum.reduce(acc, fn input, acc ->
            if Map.has_key?(input, input_key) do
              field = Enum.reverse([input_key | path])

              {message, field} = resolve_msg_field(message, field, schema_opts)

              user_error = UserError.create(message: message, field: field)

              [user_error | acc]
            else
              acc
            end
          end)
      end
    end

    defp resolve_msg_field(message, field, schema_opts) do
      case schema_opts[:resolve] do
        nil ->
          {message, field}

        fun ->
          result =
            if is_function(fun, 2) do
              fun.(message, field)
            else
              raise "Expected a 2-arity function, got: #{inspect(fun)}"
            end

          {message, field} =
            case result do
              {message, field} ->
                {message, field}

              term ->
                raise "Expected resolve function to return {message, field}, got: #{inspect(term)}"
            end

          unless is_binary(message) do
            raise "Expected message to be a string, got: #{inspect(message)}"
          end

          unless Enum.all?(field, &is_atom/1) do
            raise "Expected field to be a list of atoms, got: #{inspect(field)}"
          end

          {message, field}
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
        {^key, schema_opts} -> schema_opts
        ^key -> nil
        nil -> {:error, :not_found}
      end
    end
  end
end
