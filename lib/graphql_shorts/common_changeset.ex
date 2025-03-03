if Code.ensure_loaded?(Ecto) do
  defmodule GraphQLShorts.CommonChangeset do
    @moduledoc """
    `GraphQLShorts.CommonChangeset` maps changeset errors
    to user input based on a definition.

    ## Getting Started

    Add the `ecto` dependency to `mix.exs`:

    ```elixir
    def deps do
      [
        {:ecto, "~> 3.0"}
      ]
    end
    ```
    """
    alias GraphQLShorts.UserError

    @type user_error :: GraphQLShorts.UserError.t()

    @type input :: map()
    @type definition :: map() | keyword()
    @type opts :: keyword()

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
    to a `GraphQLShorts.UserError` struct based on the definition.

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
    @spec translate_changeset_errors(
            changeset :: map() | Ecto.Changeset.t(),
            input :: input(),
            definition :: definition()
          ) :: list(user_error())
    @spec translate_changeset_errors(
            changeset :: map() | Ecto.Changeset.t(),
            input :: input(),
            definition :: definition(),
            opts :: opts()
          ) :: list(user_error())
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

    defp recurse_build([], _input, _defn_keys, _path, acc) do
      acc
    end

    defp recurse_build([head | tail], input, defn_keys, path, acc) do
      with acc <- recurse_build(head, input, defn_keys, path, acc) do
        recurse_build(tail, input, defn_keys, path, acc)
      end
    end

    defp recurse_build({_error_key, [] = _errors}, _input, _defn_keys, _path, acc) do
      acc
    end

    defp recurse_build({error_key, [head | tail]}, input, defn_keys, path, acc) do
      with acc <- recurse_build({error_key, head}, input, defn_keys, path, acc) do
        recurse_build({error_key, tail}, input, defn_keys, path, acc)
      end
    end

    defp recurse_build({error_key, errors}, input, defn_keys, path, acc) when is_map(errors) do
      case find_definition(defn_keys, error_key) do
        {:error, :not_found} ->
          acc

        {:ok, definition} ->
          definition = definition || []

          input_key = definition[:input_key] || error_key

          if Map.has_key?(input, input_key) do
            input = Map.fetch!(input, input_key)

            defn_keys = definition[:keys] || []

            errors
            |> Map.to_list()
            |> recurse_build(input, defn_keys, [input_key | path], acc)
          else
            acc
          end
      end
    end

    defp recurse_build({error_key, message}, input, defn_keys, path, acc)
         when is_binary(message) do
      case find_definition(defn_keys, error_key) do
        {:error, :not_found} ->
          acc

        {:ok, definition} ->
          definition = definition || []

          input_key = definition[:input_key] || error_key

          input
          |> List.wrap()
          |> Enum.reduce(acc, &create_user_error(message, &1, input_key, definition, path, &2))
      end
    end

    defp create_user_error(message, input, input_key, definition, path, acc) do
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
