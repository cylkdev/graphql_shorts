defmodule GraphQLShorts.CommonErrorMessage do
  @moduledoc """
  # `GraphQLShorts.CommonErrorMessage`

  This API simplifies error code translation by mapping HTTP status codes
  to GraphQL error types. It focuses on a well-defined subset of HTTP
  status codes relevant to create, read, update, and delete (CRUD)
  operations, reducing complexity for clients.

  The module automatically selects the appropriate GraphQL error type and
  allows for configurable error messages, ensuring consistent error handling
  across applications.

  For example, an `:unauthorized` HTTP status translates into a GraphQL
  top-level error:

  ```elixir
  iex> GraphQLShorts.CommonErrorMessage.translate_error(
  ...>   %{
  ...>     code: :unauthorized,
  ...>     message: "You do not have permission to access this resource.",
  ...>     details: nil
  ...>   },
  ...>   :query
  ...> )
  [
    %GraphQLShorts.TopLevelError{
      message: "You do not have permission to access this resource.",
      code: :unauthorized,
      extensions: %{}
    }
  ]
  ```
  """
  alias GraphQLShorts.{
    TopLevelError,
    UserError
  }

  @type error_message :: %{code: atom(), message: binary(), details: nil | map()}
  @type operation :: :mutation | :query | :subscription
  @type callback :: function()
  @type opts :: keyword()

  @type top_level_error :: GraphQLShorts.TopLevelError.t()
  @type user_error :: GraphQLShorts.UserError.t()

  @logger_prefix "GraphQLShorts.CommonErrorMessage"

  # ---

  @server_error_codes ~w(
    internal_server_error
    service_unavailable
    too_many_requests
    unauthorized
  )a

  @mutation_user_induced_error_codes ~w(
    bad_request
    conflict
    forbidden
    gone
    not_found
    precondition_failed
    unprocessable_entity
  )a

  @query_user_induced_error_codes ~w(
    bad_request
    forbidden
    gone
    not_found
    unprocessable_entity
  )a

  # ---

  @default_top_level_error TopLevelError.create(
                             code: :internal_server_error,
                             message: "Looks like something unexpected went wrong.",
                             extensions: %{}
                           )

  # ---

  @top_level :top_level
  @user_error :user_error
  @undefined_field ["UNDEFINED"]

  # ---

  @mutation :mutation
  @query :query
  @subscription :subscription

  def server_error_codes, do: @server_error_codes

  def mutation_user_induced_error_codes, do: @mutation_user_induced_error_codes

  def query_user_induced_error_codes, do: @query_user_induced_error_codes

  def server_error_code?(code) do
    Enum.member?(@server_error_codes, code)
  end

  def mutation_user_induced_failure_code?(code) do
    Enum.member?(@mutation_user_induced_error_codes, code)
  end

  def query_user_induced_failure_code?(code) do
    Enum.member?(@query_user_induced_error_codes, code)
  end

  @doc """
  Translates an application error message to a GraphQL error message.

  ## Parameters

    * `error` - A map containing `:code`, `:message`, and optional `:details`.

    * `operation` - The type of GraphQL request (`:mutation`, `:query`, `:subscription`).

    * `callback` - Either :none or a 2-arity function (`fun.(error, metadata)`).

  ## Returns

  A list of `GraphQLShorts.TopLevelError` or `GraphQLShorts.UserError` structs.

  ## Operations

  The operation can be one of:

    * `:mutation`

    * `:query`

    * `:subscription` (Not yet supported)

  ## Callback Function

  If callback is `:none`, the function returns an error type as-is.
  Otherwise, it calls a `2-arity` function `fun.(error, metadata)`, where:

    * `error` is a map with :code, :message, and :details.

    * `metadata` is a map with contextual information about the error.

  The metadata map includes:

    * `:error_type` - Can be `:top_level` or `:user_error`.

    * `:induced_by_user` - `true` if the error was caused by user input.

    * `:operation` - The GraphQL request type (`:mutation`, `:query`, or
      `:subscription`).

  The callback function must return parameters for one of the error types:

    * If `:top_level`, the function must return parameters for a
      `GraphQLShorts.TopLevelError` struct.

    * If `:user_error`, the function must return parameters for a
      `GraphQLShorts.UserError` struct.

  ## Mapping HTTP Codes to GraphQL Errors

  HTTP status codes describe the outcome of an operation. To simplify
  GraphQL error handling, we categorize a small subset of relevant codes
  into meaningful groups.

  The three categories are:

    * Server Errors - Server related errors that prevent an entire operation from being executed. (e.g. internal server errors / rate-limiting errors)

    * Mutation User Errors - Business logic errors.

    * Query User-Induced Errors - Business logic errors.

  ### Server Error Codes

  These codes cover server-sided errors:

    * `:internal_server_error` - Unexpected server-side error (e.g.,
      unhandled exception, dependency failure).

    * `:service_unavailable` - Server is temporarily down or overloaded
      (e.g., maintenance, failing upstream service).

    * `:unauthorized` - Authentication failed (e.g., missing or invalid API
      token).

    * `:too_many_requests` - API request limit exceeded.

  ### Mutation User Error Codes

  These errors are predictable due to invalid input or conflicting state:

    * `:bad_request` - Malformed input (e.g., invalid ID or JSON string).

    * `:conflict` - Conflict with existing data (e.g., duplicate email).

    * `:forbidden` - Insufficient permissions (e.g., deleting another user’s post without admin rights).

    * `:gone` - The resource was deleted and cannot be retrieved (e.g., soft-deleted record).

    * `:not_found` - The requested resource does not exist (e.g., incorrect record ID).

    * `:precondition_failed` - Optimistic locking or conditional update check failed. (e.g., Trying to edit a document locked by another user).

    * `:unprocessable_entity` - Input violates business rules (e.g., weak password, invalid email format).

  ### Query User-Induced Error Codes

  These errors are predictable due to invalid input or unavailable data:

    * `:bad_request` - Malformed input (e.g., invalid ID or JSON string).

    * `:forbidden` - Insufficient permissions to access fields or resources.

    * `:gone` - The resource was deleted and cannot be retrieved.

    * `:not_found` - The requested resource does not exist.

    * `:unprocessable_entity` - Query contains valid syntax but invalid input values (e.g., filtering with an invalid date range).

  ### Examples

    iex> GraphQLShorts.CommonErrorMessage.translate_error(
    ...>   %{
    ...>     code: :too_many_requests,
    ...>     message: "please try again in a few minutes.",
    ...>     details: nil
    ...>   },
    ...>   :query
    ...> )
    [
      %GraphQLShorts.TopLevelError{
        message: "please try again in a few minutes.",
        code: :too_many_requests,
        extensions: %{}
      }
    ]
  """
  @spec translate_error(
          error :: error_message() | list(error_message()),
          operation :: operation()
        ) :: list(top_level_error() | user_error())
  @spec translate_error(
          error :: error_message() | list(error_message()),
          operation :: operation(),
          callback :: callback() | :none
        ) :: list(top_level_error() | user_error())
  @spec translate_error(
          error :: error_message() | list(error_message()),
          operation :: operation(),
          callback :: callback() | :none,
          opts :: opts()
        ) :: list(top_level_error() | user_error())
  def translate_error(error, operation, callback \\ :none, opts \\ %{})

  def translate_error(errors, operation, callback, opts) when is_list(errors) do
    Enum.flat_map(errors, &translate_error(&1, operation, callback, opts))
  end

  def translate_error(
        %{code: code, message: msg, details: details},
        @mutation,
        callback,
        opts
      ) do
    error_message = %{code: code, message: msg, details: details}

    cond do
      server_error_code?(code) ->
        metadata =
          %{
            operation: @mutation,
            error_type: @top_level,
            induced_by_user: false
          }

        result =
          if callback === :none do
            %{
              code: code,
              message: msg,
              extensions: if(opts[:show_sensitive_info] === true, do: details, else: %{})
            }
          else
            callback.(error_message, metadata)
          end

        case result do
          %{code: _, message: _, extensions: _} = params ->
            params
            |> TopLevelError.create()
            |> List.wrap()

          term ->
            raise "Expected %{code: term(), message: term(), extensions: term()}, got: #{inspect(term)}"
        end

      mutation_user_induced_failure_code?(code) ->
        metadata =
          %{
            operation: @mutation,
            error_type: @user_error,
            induced_by_user: true
          }

        result =
          if callback === :none do
            %{message: msg, field: @undefined_field}
          else
            callback.(error_message, metadata)
          end

        result
        |> List.wrap()
        |> Enum.map(fn
          %{message: _, field: _} = params ->
            params
            |> Map.put_new(:field, @undefined_field)
            |> UserError.create()

          term ->
            raise "Expected %{message: term(), field: term()}, got: #{inspect(term)}"
        end)

      true ->
        GraphQLShorts.Utils.Logger.warning(
          @logger_prefix,
          "Unrecognized mutation error code: #{inspect(code)}"
        )

        [@default_top_level_error]
    end
  end

  def translate_error(
        %{code: code, message: msg, details: details},
        @query,
        callback,
        opts
      ) do
    error_message = %{code: code, message: msg, details: details}

    cond do
      server_error_code?(code) ->
        metadata =
          %{
            operation: @query,
            error_type: @top_level,
            induced_by_user: false
          }

        result =
          if callback === :none do
            %{
              code: code,
              message: msg,
              extensions: if(opts[:show_sensitive_info] === true, do: details, else: %{})
            }
          else
            callback.(error_message, metadata)
          end

        case result do
          %{code: _, message: _, extensions: _} = params ->
            params
            |> TopLevelError.create()
            |> List.wrap()

          term ->
            raise "Expected %{code: term(), message: term(), extensions: term()}, got: #{inspect(term)}"
        end

      query_user_induced_failure_code?(code) ->
        metadata =
          %{
            operation: @query,
            error_type: @top_level,
            induced_by_user: true
          }

        result =
          if callback === :none do
            %{
              code: code,
              message: msg,
              extensions: if(opts[:show_sensitive_info] === true, do: details, else: %{})
            }
          else
            callback.(error_message, metadata)
          end

        result
        |> List.wrap()
        |> Enum.map(fn
          %{code: _, message: _, extensions: _} = params ->
            TopLevelError.create(params)

          term ->
            raise "Expected %{code: term(), message: term(), extensions: term()}, got: #{inspect(term)}"
        end)

      true ->
        GraphQLShorts.Utils.Logger.warning(
          @logger_prefix,
          "Unrecognized query error code: #{inspect(code)}"
        )

        [@default_top_level_error]
    end
  end

  def translate_error(
        %{code: _code, message: _msg, details: _details},
        @subscription,
        callback,
        _opts
      )
      when callback === :none or is_function(callback, 2) do
    raise "Not yet implemented."
  end
end
