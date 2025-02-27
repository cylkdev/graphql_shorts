if Code.ensure_loaded?(Ecto) do
  defmodule GraphQLShorts.Bridges.ChangesetBridge do
    @moduledoc """
    `GraphQLShorts.Bridges.ChangesetBridge` provides an API that
    allows to you map changeset errors to arguments and converts them
    into user errors based on a schema.
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
            definition :: map() | keyword()
          ) :: list(GraphQLShorts.UserError.t())
    @spec build_user_errors(
            changeset_or_map :: Ecto.Changeset.t() | map(),
            args :: map(),
            definition :: map() | keyword(),
            opts :: keyword()
          ) :: list(GraphQLShorts.UserError.t())
    def build_user_errors(changeset, args, definition, opts \\ [])

    def build_user_errors(changeset, args, definition, opts)
        when is_struct(changeset, Ecto.Changeset) do
      changeset
      |> errors_on_changeset()
      |> build_user_errors(args, definition, opts)
    end

    def build_user_errors(errors, args, definition, opts) do
      path = definition[:path] || []

      mappings = definition[:mappings] || []

      input = get_in(args, path) || %{}

      errors
      |> recurse_build(input, mappings, path, [], opts)
      |> Enum.reverse()
    end

    defp recurse_build(message, _input, _mappings, path, acc, opts) when is_binary(message) do
      prefix = opts[:field_prefix] || []

      path = prefix ++ Enum.reverse(path)

      user_error = UserError.create(message: message, field: path)

      [user_error | acc]
    end

    defp recurse_build([error | todo], input, mappings, path, acc, opts) do
      if Enum.any?(todo) do
        recurse_build(error, input, mappings, path, acc, opts) ++
          recurse_build(todo, input, mappings, path, acc, opts)
      else
        recurse_build(error, input, mappings, path, acc, opts)
      end
    end

    defp recurse_build(errors, input, [mappings | mappings_todo], path, acc, opts) do
      if Enum.any?(mappings_todo) do
        with acc <- recurse_build(errors, input, mappings, path, acc, opts) do
          recurse_build(errors, input, mappings_todo, path, acc, opts)
        end
      else
        recurse_build(errors, input, mappings, path, acc, opts)
      end
    end

    defp recurse_build(errors, [input | input_todo], mappings, path, acc, opts) do
      if Enum.any?(input_todo) do
        with acc <- recurse_build(errors, input, mappings, path, acc, opts) do
          recurse_build(errors, input_todo, mappings, path, acc, opts)
        end
      else
        recurse_build(errors, input, mappings, path, acc, opts)
      end
    end

    defp recurse_build(errors, input, {error_key, mappings}, path, acc, opts) do
      input_field = mappings[:field] || error_key

      input_keys = mappings[:keys]

      if Map.has_key?(errors, error_key) and is_map(input) and Map.has_key?(input, error_key) do
        input = Map.get(input, input_field)

        errors
        |> Map.fetch!(error_key)
        |> recurse_build(input, input_keys, [input_field | path], acc, opts)
      else
        acc
      end
    end

    defp recurse_build(errors, input, error_key, path, acc, opts) when is_atom(error_key) do
      if Map.has_key?(errors, error_key) and is_map(input) and Map.has_key?(input, error_key) do
        input = Map.get(input, error_key)

        errors
        |> Map.fetch!(error_key)
        |> recurse_build(input, nil, [error_key | path], acc, opts)
      else
        acc
      end
    end
  end
end
