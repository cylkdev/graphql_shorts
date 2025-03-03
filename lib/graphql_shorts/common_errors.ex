defmodule GraphQLShorts.CommonErrors do
  @moduledoc """
  # GraphQLShorts.CommonErrors

  `GraphQLShorts.CommonErrors` provides functionality
  for managing errors in a predictable way.

  ## How to Use

  The functions in this API are used by resolvers to translate
  system errors into GraphQL compliant errors.

  For example:

  ```elixir
  defmodule MyAppWeb.UserResolver do
    alias GraphQLShorts.CommonChangeset

    def create_user(%{input: input} = args, _resolution) do
      case MyApp.create_user(%{email: input.email}) do
        {:ok, user} ->
          {:ok, %{user: user}}

        {:error, e} ->
          GraphQLShorts.CommonErrors.convert_to_error_message(e,
            {
              %{is_struct: Ecto.Changeset, data: %{is_struct: MyApp.User}},
              fn changeset ->
                CommonChangeset.convert_to_graphql_user_errors(
                  changeset,
                  input,
                  keys: [:email]
                )
              end
            }
          )
      end
    end
  end
  ```
  """
  alias GraphQLShorts.TopLevelError

  @type top_level_error :: GraphQLShorts.TopLevelError.t()
  @type user_error :: GraphQLShorts.UserError.t()
  @type selector :: Matchbox.selector()
  @type selectors :: Matchbox.selectors()
  @type opts :: keyword()

  @logger_prefix "GraphQLShorts.CommonErrors"

  @fallback_top_level_error TopLevelError.create(
                              code: :internal_server_error,
                              message: "Looks like something unexpected went wrong.",
                              extensions: %{}
                            )

  @doc """
  This is a convenience function that calls `GraphQLShorts.CommonErrors.convert_to_error_message/3`
  if `response` is `{:error, term()}` or `:error`.
  """
  @spec handle_response(
          response :: {:error, term()} | :error | term(),
          selectors :: selector() | selectors()
        ) :: {:error, term()} | {:ok, term()} | :error | :ok
  @spec handle_response(
          response :: {:error, term()} | :error | term(),
          selectors :: selector() | selectors(),
          opts :: opts()
        ) :: {:error, term()} | :error | term()
  def handle_response(response, selectors, opts \\ [])

  def handle_response({:error, e}, selectors, opts) do
    {:error, convert_to_error_message(e, selectors, opts)}
  end

  def handle_response(:error, selectors, opts) do
    convert_to_error_message(:error, selectors, opts)
  end

  def handle_response(res, _, _), do: res

  @doc """
  Changes `term` into a `GraphQLShorts.TopLevelError` or
  `GraphQLShorts.UserError` struct based on `selectors`.

  ### Examples

      iex> GraphQLShorts.CommonErrors.convert_to_error_message(
      ...>   %{code: :not_found, message: "no records found", details: %{query: MyApp.Schemas.User, params: %{id: 1}}},
      ...>   {
      ...>     %{code: :not_found},
      ...>     fn e ->
      ...>       GraphQLShorts.TopLevelError.create(
      ...>         code: e.code,
      ...>         message: e.message,
      ...>         extensions: %{id: e.details.params.id, documentation: "http://api.docs.com"}
      ...>       )
      ...>     end
      ...>   }
      ...> )
      [
        %GraphQLShorts.TopLevelError{
          code: :not_found,
          message: "no records found",
          extensions: %{
            id: 1,
            documentation: "http://api.docs.com"
          }
        }
      ]
  """
  @spec convert_to_error_message(
          error :: term(),
          selectors :: selector() | selectors()
        ) :: list(top_level_error() | user_error())
  @spec convert_to_error_message(
          error :: term(),
          selectors :: selector() | selectors(),
          opts :: keyword()
        ) :: list(top_level_error() | user_error())
  def convert_to_error_message(error, selectors, opts \\ [])

  def convert_to_error_message(error, selectors, opts) when is_list(error) do
    error = if Keyword.keyword?(error), do: [error], else: error

    Enum.flat_map(error, &apply_selector(&1, selectors, opts))
  end

  def convert_to_error_message(error, selectors, opts) do
    apply_selector(error, selectors, opts)
  end

  defp apply_selector(term, selectors, opts) do
    {result, passed?} = Matchbox.transform(term, selectors, opts)

    if passed? do
      if is_list(result) do
        ensure_error_structs!(result)

        result
      else
        ensure_error_struct!(result)

        [result]
      end
    else
      GraphQLShorts.Utils.Logger.warning(
        @logger_prefix,
        """
        selectors did not match term.

        selectors:
        #{inspect(selectors)}

        term:
        #{inspect(term, pretty: true)}
        """
      )

      [@fallback_top_level_error]
    end
  end

  defp ensure_error_struct!(result) do
    unless error_struct?(result) do
      raise ArgumentError, """
      Expected a `GraphQLShorts.TopLevelError` or `GraphQLShorts.UserError` struct.

      got:
      #{inspect(result, pretty: true)}
      """
    end
  end

  defp ensure_error_structs!(result) do
    unless Enum.all?(result, &error_struct?/1) do
      raise ArgumentError, """
      Expected a list of `GraphQLShorts.TopLevelError` or `GraphQLShorts.UserError` structs.

      got:
      #{inspect(result, pretty: true)}
      """
    end
  end

  defp error_struct?(struct) when is_struct(struct, GraphQLShorts.TopLevelError), do: true
  defp error_struct?(struct) when is_struct(struct, GraphQLShorts.UserError), do: true
  defp error_struct?(_), do: false
end
