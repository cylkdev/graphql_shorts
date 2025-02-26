if Code.ensure_loaded?(Ecto) do
  defmodule GraphQLShorts.Bridges.ChangesetBridge do
    @moduledoc """
    `GraphQLShorts.Bridges.ChangesetBridge` provides an API that
    allows to you map changeset errors to arguments and converts them
    into user errors based on a schema.
    """
    alias GraphQLShorts.UserError

    @logger_prefix "GraphQLShorts.Bridges.ChangesetBridge"

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

    ### Examples

        iex> GraphQLShorts.Bridges.ChangesetBridge.build_user_errors(
        ...>   %{title: ["can't be blank"]},
        ...>   %{input: %{title: ""}},
        ...>   [path: [:input], mappings: [:title]]
        ...> )
        [
          %GraphQLShorts.UserError{
            message: "can't be blank",
            field: [:input, :title]
          }
        ]
    """
    @spec build_user_errors(
            changeset_or_map :: Ecto.Changeset.t() | map(),
            args :: map(),
            schema :: map() | keyword()
          ) :: list(GraphQLShorts.UserError.t())
    @spec build_user_errors(
            changeset_or_map :: Ecto.Changeset.t() | map(),
            args :: map(),
            schema :: map() | keyword(),
            opts :: keyword()
          ) :: list(GraphQLShorts.UserError.t())
    def build_user_errors(changeset, args, schema, opts \\ [])

    def build_user_errors(changeset, args, schema, opts)
        when is_struct(changeset, Ecto.Changeset) do
      changeset
      |> errors_on_changeset()
      |> build_user_errors(args, schema, opts)
    end

    def build_user_errors(errors, args, schema, opts) do
      path = schema[:path] || []
      keys = schema[:mappings] || []

      input_args = get_in(args, path) || %{}

      errors
      |> recurse_build(input_args, keys, path, [], opts)
      |> Enum.reverse()
    end

    defp recurse_build(message, _args, schema, path, acc, opts) when is_binary(message) do
      prefix = opts[:field_prefix] || []

      path = prefix ++ Enum.reverse(path)

      unless is_nil(schema) do
        GraphQLShorts.Utils.Logger.warning(
          @logger_prefix,
          "The option `:keys` is not expected at path #{inspect(path)} and is ignored."
        )
      end

      [UserError.create(message: message, field: path) | acc]
    end

    defp recurse_build([error | todo], args, schema, path, acc, opts) do
      if Enum.any?(todo) do
        recurse_build(error, args, schema, path, acc, opts) ++
          recurse_build(todo, args, schema, path, acc, opts)
      else
        recurse_build(error, args, schema, path, acc, opts)
      end
    end

    defp recurse_build(errors, args, [schema | schema_todo], path, acc, opts) do
      if Enum.any?(schema_todo) do
        with acc <- recurse_build(errors, args, schema, path, acc, opts) do
          recurse_build(errors, args, schema_todo, path, acc, opts)
        end
      else
        recurse_build(errors, args, schema, path, acc, opts)
      end
    end

    defp recurse_build(errors, [args | args_todo], schema, path, acc, opts) do
      if Enum.any?(args_todo) do
        with acc <- recurse_build(errors, args, schema, path, acc, opts) do
          recurse_build(errors, args_todo, schema, path, acc, opts)
        end
      else
        recurse_build(errors, args, schema, path, acc, opts)
      end
    end

    defp recurse_build(errors, args, {error_key, schema}, path, acc, opts) do
      input_field = schema[:field] || error_key

      input_keys = schema[:keys]

      if Map.has_key?(errors, error_key) and is_map(args) and Map.has_key?(args, error_key) do
        input_args = Map.get(args, input_field)

        errors
        |> Map.fetch!(error_key)
        |> recurse_build(input_args, input_keys, [input_field | path], acc, opts)
      else
        acc
      end
    end

    defp recurse_build(errors, args, error_key, path, acc, opts) when is_atom(error_key) do
      if Map.has_key?(errors, error_key) and is_map(args) and Map.has_key?(args, error_key) do
        input_args = Map.get(args, error_key)

        errors
        |> Map.fetch!(error_key)
        |> recurse_build(input_args, nil, [error_key | path], acc, opts)
      else
        acc
      end
    end
  end
end
