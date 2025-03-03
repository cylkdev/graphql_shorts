defmodule GraphQLShorts.CommonErrorHandler do
  @moduledoc """
  # GraphQLShorts.CommonErrorHandler

  `GraphQLShorts.CommonErrorHandler` provides functionality
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
          GraphQLShorts.CommonErrorHandler.convert_to_error_message(e, [
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
          ])
      end
    end
  end
  ```
  """
  alias GraphQLShorts.TopLevelError

  @type graphql_error_message :: GraphQLShorts.TopLevelError.t() | GraphQLShorts.UserError.t()

  @type condition :: {expression :: term(), fun :: function()}
  @type conditions :: condition() | list(condition())

  @logger_prefix "GraphQLShorts.CommonErrorHandler"

  @doc """
  ...
  """
  def handle_error_response({:error, e}, conditions, opts) do
    {:error, convert_to_error_message(e, conditions, opts)}
  end

  def handle_error_response(:error, conditions, opts) do
    {:error, convert_to_error_message(:error, conditions, opts)}
  end

  def handle_error_response(response, _conditions, _opts) do
    response
  end

  @doc """
  Changes `term` into a `GraphQLShorts.TopLevelError` or `GraphQLShorts.UserError`
  struct based on `conditions`.

  ### Examples

      iex> GraphQLShorts.CommonErrorHandler.convert_to_error_message(
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
  def convert_to_error_message(term, conditions, opts \\ [])

  def convert_to_error_message(term, conditions, opts) when is_list(term) do
    term =
      if Keyword.keyword?(term) do
        [term]
      else
        term
      end

    Enum.flat_map(term, &transform_error(&1, conditions, opts))
  end

  def convert_to_error_message(term, conditions, opts) do
    transform_error(term, conditions, opts)
  end

  defp transform_error(term, conditions, opts) do
    {result, passed?} = Matchbox.transform(term, conditions, opts)

    if passed? do
      if is_list(result) do
        unless Enum.all?(result, &error_struct?/1) do
          raise ArgumentError, """
          Expected a list of `GraphQLShorts.TopLevelError` or `GraphQLShorts.UserError` structs.

          got:
          #{inspect(result, pretty: true)}
          """
        end

        result
      else
        unless error_struct?(result) do
          raise ArgumentError, """
          Expected a `GraphQLShorts.TopLevelError` or `GraphQLShorts.UserError` struct.

          got:
          #{inspect(result, pretty: true)}
          """
        end

        [result]
      end
    else
      GraphQLShorts.Utils.Logger.warning(
        @logger_prefix,
        """
        Conditions did not match term.

        conditions:
        #{inspect(conditions)}

        term:
        #{inspect(term, pretty: true)}
        """
      )

      [build_fallback_error_message(opts)]
    end
  end

  defp error_struct?(struct) when is_struct(struct, GraphQLShorts.TopLevelError), do: true
  defp error_struct?(struct) when is_struct(struct, GraphQLShorts.UserError), do: true
  defp error_struct?(_), do: false

  defp build_fallback_error_message(opts) do
    params = opts[:fallback_error_message] || %{}

    TopLevelError.create(
      code: :internal_server_error,
      message: "Looks like something unexpected went wrong.",
      extensions: params[:extensions] || %{}
    )
  end
end
