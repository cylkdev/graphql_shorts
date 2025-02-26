if Code.ensure_loaded?(ErrorMessage) do
  defmodule GraphQLShorts.Bridges.ErrorMessageBridge do
    @moduledoc false

    def build_user_errors(_changeset, _args, _schema, _opts) do
      raise "Not yet implemented."
    end
  end
end
