defmodule GraphQLShorts.CommonErrors do
  @moduledoc """
  `GraphQLShorts.CommonErrors` focuses on standardizing the error handling
  behaviour in your application.
  """

  @type graphql_error_message :: GraphQLShorts.TopLevelError.t() | GraphQLShorts.UserError.t()

  @type condition :: {expression :: term(), fun :: function()}
  @doc """
  Transforms any `{:error, term()}` responses based on the given conditions.

  ### Examples

      iex> GraphQLShorts.CommonErrors.handle_error_response(
      ...>   {:error, %{code: :not_found, message: "no records found", details: %{query: MyApp.Schemas.User, params: %{id: 1}}}},
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
      {:error,
        [
          %GraphQLShorts.TopLevelError{
            code: :not_found,
            message: "no records found",
            extensions: %{
              id: 1,
              documentation: "http://api.docs.com"
            },
            field: nil
          }
        ]
      }
  """
  @spec handle_error_response(
          response :: term(),
          conditions :: condition() | list(condition()),
          fun :: function()
        ) :: {:ok, term()} | {:error, list(graphql_error_message())}
  @spec handle_error_response(
          response :: term(),
          conditions :: condition() | list(condition()),
          opts :: keyword()
        ) :: {:ok, term()} | {:error, list(graphql_error_message())}
  def handle_error_response(response, conditions, opts \\ [])

  def handle_error_response({:error, term}, conditions, opts) do
    errors =
      if is_list(term) and not Keyword.keyword?(term) do
        Enum.flat_map(term, &transform_term(&1, conditions, opts))
      else
        transform_term(term, conditions, opts)
      end

    {:error, errors}
  end

  def handle_error_response({:ok, _} = res, _, _), do: res

  defp transform_term(term, conditions, opts) do
    case Matchbox.transform(term, conditions, opts) do
      results when is_list(results) ->
        unless Enum.all?(results, &error_struct?/1) do
          raise ArgumentError, """
          Expected a list with only `GraphQLShorts.TopLevelError` or `GraphQLShorts.UserError` structs.

          got:

          #{inspect(results, pretty: true)}
          """
        end

        results

      result ->
        unless error_struct?(result) do
          raise ArgumentError, """
          Expected a `GraphQLShorts.TopLevelError` or `GraphQLShorts.UserError` struct.

          got:

          #{inspect(result, pretty: true)}
          """
        end

        [result]
    end
  end

  defp error_struct?(struct) when is_struct(struct, GraphQLShorts.TopLevelError), do: true
  defp error_struct?(struct) when is_struct(struct, GraphQLShorts.UserError), do: true
  defp error_struct?(_), do: false
end
