defmodule GraphQLShorts.Config do
  @moduledoc false
  @app :graphql_shorts

  @doc false
  @spec json_adapter :: atom()
  def json_adapter do
    Application.get_env(@app, :json_adapter) || Jason
  end
end
