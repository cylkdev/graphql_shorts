if Code.ensure_loaded?(Absinthe) do
  defmodule GraphQLShorts.Absinthe.Middleware do
    @moduledoc """
    # GraphQLShorts.Absinthe.Middleware

    This post-resolution middleware focuses on providing a predictable
    GraphQL response. This middleware does not process any errors.
    Instead, it expects the resolver to translate application errors
    to a `GraphQLShorts.TopLevelError` or `GraphQLShorts.UserError`
    struct and it will adjust the response based on the operation.

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

    If the mutation partially fails due to user error, the response would be:

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

    If the mutation fails entirely, the response would be:

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

    Unlike mutations, Queries do not not define their own custom payloads,
    instead they return the data directly. When a query error occurs, the
    response would be:

    ```elixir
    %{
      data: %{ "user" => nil },
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

      - The user errors are put in the `:user_errors` key of
        the mutation payload.

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
        {top_level_errors, user_errors} = sort_errors(errors)

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
        {top_level_errors, user_errors} = sort_errors(errors)

        if Enum.any?(top_level_errors) do
          top_level_errors = GraphQLShorts.TopLevelError.to_json(top_level_errors, opts)

          %{resolution | value: nil, errors: top_level_errors}
        else
          user_errors = GraphQLShorts.UserError.to_json(user_errors, opts)

          value =
            value
            |> Map.put(@user_errors, user_errors)
            |> Map.put(:success, false)

          %{resolution | value: value, errors: []}
        end
      else
        %{resolution | value: Map.put(value, :success, true)}
      end
    end

    defp sort_errors(errors) do
      errors
      |> List.wrap()
      |> Enum.reduce({[], {}}, &reduce_sort_error/2)
    end

    defp reduce_sort_error(error, {top_level_errors, user_errors})
         when is_struct(error, GraphQLShorts.TopLevelError) do
      {[error | top_level_errors], user_errors}
    end

    defp reduce_sort_error(error, {top_level_errors, user_errors})
         when is_struct(error, GraphQLShorts.UserError) do
      {top_level_errors, [error | user_errors]}
    end

    defp reduce_sort_error(term, {top_level_errors, user_errors}) do
      GraphQLShorts.Utils.Logger.warning(
        @logger_prefix,
        """
        Resolver returned unrecognized error.

        Expected one of:

          - A `GraphQLShorts.TopLevelError` struct
          - A `GraphQLShorts.UserError` struct

        Got:
        #{inspect(term, pretty: true)}
        """
      )

      error =
        TopLevelError.create(%{
          code: :internal_server_error,
          message: "An unexpected error occurred, please try again later."
        })

      {[error | top_level_errors], user_errors}
    end
  end
end
