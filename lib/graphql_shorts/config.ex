defmodule GraphQLShorts.Config do
  @moduledoc false
  @app :graphql_shorts

  @doc false
  @spec json_adapter :: atom()
  def json_adapter do
    Application.get_env(@app, :json_adapter) || Jason
  end

  @doc false
  @spec absinthe_middleware :: atom()
  def absinthe_middleware do
    Application.get_env(@app, :absinthe_middleware) ||
      [
        on_unrecognized_error: :warn,
        user_error_key: :user_errors
      ]
  end
end
