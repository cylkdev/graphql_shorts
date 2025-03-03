if Code.ensure_loaded?(Absinthe) do
  defmodule GraphQLShorts.Absinthe.Middleware do
    @moduledoc """
    `GraphQLShorts.Absinthe.Middleware` is a post-resolution middleware for
    handling GraphQL errors. This middleware categorizes and formats errors
    returned by resolvers ensuring a predictable standardized response.

    This middleware:

      - Categorizes errors into top-level errors and user errors.

      - Formats errors according to GraphQL conventions.

      - Ensures field-specific errors appear inside mutation payloads.

    ## Error Types

    Errors fall into one of two types:

      - **Top-Level Errors (Operation-Level Failures):** These errors imply that
        the entire operation failed and cannot be executed. This typically occurs
        due to permission issues, authentication failures, or other critical
        failures that prevent the query from running.

      - **User Errors (Field-Specific Failures):** These errors imply that the
        query itself was executed, but certain fields failed due to validation
        issues or business logic constraints (e.g., an email that does not meet
        the required format). These errors are returned as part of the mutation
        payload, allowing partial responses.


    ## Error Handling

    This middleware does not transform errors itself. Instead, it expects the resolver
    to return one of the following:

      - `GraphQLShorts.TopLevelError` for operation-level failures.

      - `GraphQLShorts.UserError` for field-specific failures.

    See `GraphQLShorts.CommonErrors.convert_to_error_message/3` for details on how to structure errors.

    ## Example

    Given the following mutation:

    ```elixir
    mutation {
      createUser(input: { email: "invalid", password: "123" }) {
        user {
          id
          email
        }
        userErrors {
          field
          message
        }
      }
    }
    ```

    If the provided email is invalid (a field-specific error) the response would be:

    ```elixir
    %{
      data: {
        "createUser" => {
          "user" => null,
          "success" => false,
          "userErrors" => [
            %{
              "field" => "email",
              "message" => "Invalid email format."
            }
          ]
        }
      }
    }
    ```

    If an operation were to fail entirely due to authentication issues,
    the response would be:

    ```elixir
    %{
      data: %{ "createUser" => nil },
      errors: [
        %{
          "message" => "Unauthorized",
          "extensions" => {
            "code" => "UNAUTHORIZED"
          }
        }
      ]
    }
    ```
    """
    alias GraphQLShorts.{
      Absinthe.ResolutionHelpers,
      TopLevelError
    }

    @logger_prefix "GraphQLShorts.Absinthe.Middleware"

    @warn :warn
    @user_errors :user_errors

    @doc """
    This function examines the resolution struct to determine
    how errors should be handled. If top-level errors exist,
    they replace the `:errors` field, and no data is returned.
    If only user errors exist, they are merged into the
    resolved data under a configurable key. Unrecognized errors
    are ignored, and a warning is logged.

    This function resolves as follows:

    1. If any `GraphQLShorts.TopLevelError` exists in `:errors`:

      - The `:errors` field on the resolution struct is
        replaced with only `GraphQLShorts.TopLevelError` structs.

      - `:value` on the resolution struct is set to nil,
        ensuring no data is returned.

      - Any `GraphQLShorts.UserError` structs are ignored, as operation-level
        failures prevent field resolution.

    2. If only `GraphQLShorts.UserError` structs exist in `:errors`:

      - The existing data in `:value` on the resolution struct
        is preserved.

      - The user errors are put in the resolved mutation
        payload under the configured `:user_error_key`.

      - The `:success` field is set to `false` on the existing
        data in `:value`, indicating failure.

      - The `:errors` on the resolution struct field is cleared.

    3. If no errors exist:

      - The `:success` field on the mutation payload is set to
        `true`, indicating success.

      - The data in `:value` on the resolution struct remains
        unchanged.

    4. If an unrecognized error type is found:

      - The error is ignored.

      - A warning is logged.

      - A default top-level error is returned, treating the
        operation as a failure.

    ### Examples

        GraphQLShorts.Absinthe.Middleware.call(%Absinthe.Resolution{
          state: :resolved,
          errors: [ %GraphQLShorts.TopLevelError{} ]
        })

        GraphQLShorts.Absinthe.Middleware.call(%Absinthe.Resolution{
          state: :resolved,
          errors: [ %GraphQLShorts.UserError{} ]
        })
    """
    @spec call(resolution :: Absinthe.Resolution.t()) :: Absinthe.Resolution.t()
    @spec call(resolution :: Absinthe.Resolution.t(), opts :: keyword()) ::
            Absinthe.Resolution.t()
    def call(
          %{
            state: :resolved,
            errors: errors,
            value: value
          } = resolution,
          opts \\ []
        ) do
      errors = List.wrap(errors)

      value = value || %{}

      resolution = %{resolution | errors: errors, value: value}

      if ResolutionHelpers.operation_type(resolution) === :mutation do
        resolve_mutation(resolution, opts)
      else
        resolve_query(resolution, opts)
      end
    end

    defp resolve_query(%{errors: errors} = resolution, opts) do
      if Enum.any?(errors) do
        {top_level_errors, user_errors} = sort_errors(errors, opts)

        if Enum.any?(user_errors) do
          path = Absinthe.Resolution.path(resolution)

          GraphQLShorts.Utils.Logger.warning(
            @logger_prefix,
            """
            `UserError` structs are not allowed on queries.
            Resolver functions can only return `TopLevel`
            structs for query operations.

            path:
            #{inspect(path)}
            """
          )
        end

        if Enum.any?(top_level_errors) do
          top_level_errors = GraphQLShorts.TopLevelError.to_json(top_level_errors, opts)

          %{resolution | value: nil, errors: top_level_errors}
        else
          path = Absinthe.Resolution.path(resolution)

          raise """
          Resolver did not return a `TopLevelError` struct(s) for query.

          path:
          #{inspect(path)}
          """
        end
      else
        resolution
      end
    end

    defp resolve_mutation(%{errors: errors, value: value} = resolution, opts) do
      if Enum.any?(errors) do
        {top_level_errors, user_errors} = sort_errors(errors, opts)

        if Enum.any?(top_level_errors) do
          top_level_errors = GraphQLShorts.TopLevelError.to_json(top_level_errors, opts)

          %{resolution | value: nil, errors: top_level_errors}
        else
          user_errors = GraphQLShorts.UserError.to_json(user_errors, opts)

          user_error_key = user_error_key(opts)

          value =
            value
            |> Map.put(user_error_key, user_errors)
            |> Map.put(:success, false)

          %{resolution | value: value, errors: []}
        end
      else
        %{resolution | value: Map.put(value, :success, true)}
      end
    end

    defp sort_errors(errors, opts) do
      errors
      |> List.wrap()
      |> Enum.reduce({[], {}}, &reduce_sort_error(&1, &2, opts))
    end

    defp reduce_sort_error(error, {top_level_errors, user_errors}, _opts)
         when is_struct(error, GraphQLShorts.TopLevelError) do
      {[error | top_level_errors], user_errors}
    end

    defp reduce_sort_error(error, {top_level_errors, user_errors}, _opts)
         when is_struct(error, GraphQLShorts.UserError) do
      {top_level_errors, [error | user_errors]}
    end

    defp reduce_sort_error(term, {top_level_errors, user_errors}, opts) do
      unrecognized_term_message =
        """
        Resolver returned unrecognized error.

        Expected one of:

          - A `GraphQLShorts.TopLevelError` struct
          - A `GraphQLShorts.UserError` struct

        Got:
        #{inspect(term, pretty: true)}
        """

      case opts[:on_unrecognized_error] ||
             GraphQLShorts.Config.absinthe_middleware()[:on_unrecognized_error] || @warn do
        :nothing -> :ok
        :raise -> raise unrecognized_term_message
        :warn -> GraphQLShorts.Utils.Logger.warning(@logger_prefix, unrecognized_term_message)
      end

      error =
        TopLevelError.create(%{
          code: :internal_server_error,
          message: "An unexpected error occurred, please try again later."
        })

      {[error | top_level_errors], user_errors}
    end

    defp user_error_key(opts) do
      opts[:user_error_key] ||
        GraphQLShorts.Config.absinthe_middleware()[:user_error_key] ||
        @user_errors
    end
  end
end
