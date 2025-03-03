defmodule GraphQLShorts.CommonErrorMessage do
  @moduledoc """
  # `GraphQLShorts.CommonErrorMessage`

  `GraphQLShorts.CommonErrorMessage` API simplifies error code
  translation by mapping HTTP status codes to GraphQL error types. This API
  supports a small subset of HTTP status codes relevant to create, read, update,
  and delete operations, reducing the error handling complexity for clients. It
  allows you to configure detailed error messages without manually determining
  the appropriate GraphQL error type.
  """
  alias GraphQLShorts.{
    TopLevelError,
    UserError
  }

  @type error_map :: %{code: atom(), message: binary(), details: nil | map()}
  @type error_maps :: list(error_map())
  @type operation :: :mutation | :query | :subscription
  @type opts :: keyword()

  @type top_level_error :: GraphQLShorts.TopLevelError.t()
  @type user_error :: GraphQLShorts.UserError.t()

  @type top_level_reason_atom ::
          :internal_service_error
          | :service_unavailable
          | :too_many_requests
          | :unauthorized

  @type user_error_reason_atom ::
          :bad_request
          | :conflict
          | :forbidden
          | :gone
          | :not_found
          | :precondition_failed
          | :unprocessable_entity

  @logger_prefix "GraphQLShorts.CommonErrorMessage"

  # Mutation Error Codes

  @mutation_top_level_error_codes ~w(
    internal_server_error
    service_unavailable
    too_many_requests
    unauthorized
  )a

  @mutation_user_error_codes ~w(
    bad_request
    conflict
    forbidden
    gone
    not_found
    precondition_failed
    unprocessable_entity
  )a

  # Query Error Codes

  @query_top_level_error_codes ~w(
    internal_server_error
    service_unavailable
    too_many_requests
    unauthorized
  )a

  @query_field_specific_error_codes ~w(
    conflict
    forbidden
    gone
    not_found
    unprocessable_entity
  )a

  @fallback_top_level_error TopLevelError.create(
                              code: :internal_server_error,
                              message: "Looks like something unexpected went wrong.",
                              extensions: %{}
                            )

  @doc """
  Converts an `ErrorMessage` struct to a `GraphQLShorts.TopLevelError`
  or `GraphQLShorts.UserError` struct.

  The `operation` can be one of:

    * `:mutation`
    * `:query`

  Note: Subscriptions are not yet supported.

  This function maps HTTP status codes to a GraphQL error type based
  on the operation type and whether the operation is creating,
  reading, updating, or deleting a resource.

  ## Mutation Error Codes

  These codes cover data modification operations (e.g. creating,
  updating, or deleting records) and typically result from invalid
  input or conflicting state.

    * `:bad_request` (User Error) - The request is malformed or structurally invalid
      (e.g. missing required fields, invalid JSON, unsupported enum value).

    * `:conflict` (User Error) - The request failed due to a conflict with existing
      data (e.g. trying to create a user with an email that already exists).

    * `:forbidden` (User Error) - The user is authenticated but lacks permission to
      perform this action (e.g. attempting to delete another user’s post without
      admin rights).

    * `:gone` (User Error) - The requested resource was explicitly deleted and is
      no longer retrievable (e.g. trying to access a soft-deleted order).

    * `:internal_server_error` (Top-Level Error) - An unexpected server-side error
      occurred (e.g. unhandled exception, dependency failure).

    * `:not_found` (User Error) - The requested resource does not exist (e.g.,
      attempting to update a record with an incorrect ID). GraphQL APIs may choose
      to return `nil` for missing resources instead of explicitly throwing this
      error.

    * `:precondition_failed` (User Error) - A conditional update or optimistic
      locking check failed (e.g., trying to update a resource with an outdated
      version number).

    * `:service_unavailable` (Top-Level Error) - The server is temporarily down or
      overloaded (e.g., undergoing maintenance, failing upstream service).

    * `:too_many_requests` (Top-Level Error) - The user has exceeded API rate
      limits (e.g., making too many API calls in a short time). If rate limits apply
      per-user, this could be considered a user error, but if system-wide, it
      remains a top-level error.

    * `:unauthorized` (Top-Level Error) - The user failed authentication (e.g.
      missing or invalid API token).

    * `:unprocessable_entity` (User Error) – The input violates business rules
      (e.g. weak password, invalid email format, age below minimum allowed).

  ## Query Error Codes

  These codes cover client requests for invalid or unavailable data. Unlike
  mutations, queries do not result in user errors and only return top-level
  errors.

    * `:conflict` (Field-Specific Error) - The request failed due to conflicts with
      existing data (e.g. trying to create a user with a duplicate email).

    * `:forbidden` (Field-Specific Error) - The user is authenticated but lacks
      permission to access certain fields or resources (e.g., querying restricted
      user details without admin rights).

    * `:gone` (Field-Specific Error) - The resource was explicitly deleted and
      cannot be retrieved again.

    * `:internal_server_error` (Top-Level Error) - A server-side failure occurred
      during query execution.

    * `:not_found` (Field-Specific Error) - The requested resource does not exist
      (e.g., looking up a non-existent record by ID). GraphQL APIs may return `null`
      instead of throwing this error.

    * `:service_unavailable` (Top-Level Error) - The server is temporarily down or
      under heavy load.

    * `:too_many_requests` (Top-Level Error) - The client has exceeded API request
      limits.

    * `:unauthorized` (Top-Level Error) - Authentication failure prevents query
      execution.

    * `:unprocessable_entity` (Field-Specific Error) – The query contains valid
      syntax but invalid input values (e.g. filtering with an invalid date range).

  ### Options

    * `:resolve`

  ### Examples

      iex> GraphQLShorts.CommonErrorMessage.translate_error(
      ...>   %ErrorMessage{
      ...>     code: :forbidden,
      ...>     message: "You do not have permission to access this resource.",
      ...>     details: %{extra: "information"}
      ...>   },
      ...>  :mutation,
      ...>   %{field: [:input, :id]}
      ...> )
      [
        %GraphQLShorts.UserError{
          field: [:input, :id],
          message: "You do not have permission to access this resource."
        }
      ]
  """
  @spec translate_error(
          error :: error_map() | error_maps(),
          operation :: operation()
        ) :: list(top_level_error() | user_error())
  @spec translate_error(
          error :: error_map() | error_maps(),
          operation :: operation(),
          opts :: opts()
        ) :: list(top_level_error() | user_error())
  def translate_error(error, operation, opts \\ [])

  def translate_error(errors, operation, opts) when is_list(errors) do
    Enum.flat_map(errors, &translate_error(&1, operation, opts))
  end

  def translate_error(
        %{
          code: code,
          message: message,
          details: details
        },
        :mutation,
        opts
      ) do
    resolve = opts[:resolve] || (&Function.identity/1)

    cond do
      Enum.member?(@mutation_top_level_error_codes, code) ->
        %{
          code: code,
          message: message,
          extensions: details || %{}
        }
        |> resolve.()
        |> TopLevelError.create()
        |> List.wrap()

      Enum.member?(@mutation_user_error_codes, code) ->
        %{
          message: message,
          field: opts[:field] || ["unknown"]
        }
        |> resolve.()
        |> List.wrap()
        |> Enum.map(&UserError.create/1)

      true ->
        GraphQLShorts.Utils.Logger.warning(
          @logger_prefix,
          "Unrecognized mutation error code: #{inspect(code)}"
        )

        [@fallback_top_level_error]
    end
  end

  def translate_error(
        %{
          code: code,
          message: message,
          details: details
        },
        :query,
        opts
      ) do
    resolve = opts[:resolve] || (&Function.identity/1)

    cond do
      Enum.member?(@query_top_level_error_codes, code) ->
        %{
          code: code,
          message: message,
          extensions: details || %{}
        }
        |> resolve.()
        |> TopLevelError.create()
        |> List.wrap()

      Enum.member?(@query_field_specific_error_codes, code) ->
        %{
          code: code,
          message: message,
          extensions: details || %{}
        }
        |> resolve.()
        |> List.wrap()
        |> Enum.map(&TopLevelError.create/1)

      true ->
        GraphQLShorts.Utils.Logger.warning(
          @logger_prefix,
          "Unrecognized query error code: #{inspect(code)}"
        )

        [@fallback_top_level_error]
    end
  end

  def translate_error(
        %{
          code: _code,
          message: _message,
          details: _details
        },
        :subscription,
        _opts
      ) do
    raise "Not yet implemented."
  end
end
