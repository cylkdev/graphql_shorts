defmodule GraphQLShorts.CommonErrors do
  @moduledoc """
  ...
  """

  @logger_prefix "GraphQLShorts"

  @doc """
  ...
  """
  @spec handle_error_response(
          response :: term(),
          expression :: term(),
          fun :: function()
        ) :: term()
  @spec handle_error_response(
          response :: term(),
          expression :: term(),
          fun :: function(),
          opts :: keyword()
        ) :: term()
  def handle_error_response(response, expression, fun, opts \\ []) do
    case response do
      {:error, term} ->
        term =
          if is_list(term) and not Keyword.keyword?(term) do
            Enum.map(term, &Matchbox.transform(&1, expression, fun, opts))
          else
            Matchbox.transform(term, expression, fun, opts)
          end

        {:error, term}

      {:ok, _} = res ->
        res

      term ->
        GraphQLShorts.Utils.Logger.warning(
          @logger_prefix,
          "Expected response to be '{:ok, term()}' or '{:error, term()}', got: #{inspect(term)}"
        )

        term
    end
  end
end
