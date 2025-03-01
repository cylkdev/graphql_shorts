if Code.ensure_loaded?(ErrorMessage) do
  defmodule GraphQLShorts.Bridges.ErrorMessageBridge do
    @moduledoc """

    Top-Level Errors

      - `:internal_server_error` - An unexpected error occurred on the server (e.g., unhandled exception, dependency failure).

      - `:service_unavailable` - The server is temporarily down or overloaded (e.g., undergoing maintenance, failing upstream service).

      - `:too_many_requests` - The user has exceeded rate limits (e.g., making too many API calls in a short time).

      - `:unauthorized` - The user failed authentication (e.g., missing or invalid API token).

    User Errors

      * `:bad_request` - The request was malformed or invalid (e.g., missing required fields, invalid JSON format, unsupported enum value).

      * `:conflict` - The mutation conflicts with existing data (e.g., trying to create a user with a duplicate email).

      * `:forbidden` - The user is authenticated but lacks permission (e.g., attempting to delete another user’s post without admin rights).

      * `:gone` - The resource was deleted and is no longer retrievable (e.g., trying to access a soft-deleted order).

      * `:not_found` - The requested resource does not exist (e.g., using an incorrect ID for a lookup).

      * `:precondition_failed` - A conditional update or optimistic locking check failed (e.g., trying to update a resource with an outdated version).

      * `:unprocessable_entity` – The input violates business rules (e.g., weak password, invalid email format, age below minimum allowed).

    """

    @top_level_error_codes ~w(
      internal_server_error
      service_unavailable
      too_many_requests
      unauthorized
    )a

    @user_error_codes ~w(
      bad_request
      conflict
      forbidden
      gone
      not_found
      precondition_failed
      unprocessable_entity
    )a

    def convert_to_error_message(
      %{code: code, message: message, details: details},
      args,
      schema_opts,
      _opts
    ) do
      path = Keyword.fetch!(schema_opts, :path)

      input = get_in(args, path)

      input =
        if is_map(input) do
          input
        else
          GraphQLShorts.Utils.Logger.warning(
            @logger_prefix,
            "Input not found at path #{inspect(path)} in arguments, got: #{inspect(args)}"
          )

          %{}
        end

      details
      |> Map.get(:params, %{})
      |> recurse_build(input, {code, message}, schema_opts[:keys] || [], path, [])
    end

    defp recurse_build(errors, _code_msg, input, keys, path, acc) do
      require IEx
      IEx.pry()
    end
  end
end
