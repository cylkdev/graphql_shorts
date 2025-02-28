if Code.ensure_loaded?(ErrorMessage) do
  defmodule GraphQLShorts.Bridges.ErrorMessageBridge do
    @moduledoc false

    def convert_to_error_message(_changeset, _args, _schema, _opts) do
      raise "Not yet implemented."
    end
  end
end
