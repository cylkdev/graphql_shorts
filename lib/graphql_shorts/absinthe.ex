defmodule GraphQLShorts.Absinthe do
  @moduledoc """
  # GraphQLShorts.Absinthe

  ## Introduction

  When handling errors in Absinthe, a crucial decision is whether to
  process them inside resolvers or in middleware. While middleware
  can standardize error responses, handling errors inside resolvers
  is often more effective because it preserves crucial contextual
  information. Middleware, on the other hand, operates at a higher
  level of abstraction, which can obscure important details.

  Resolvers have direct access to all relevant execution details at
  the moment an error occurs, including:

    * The query arguments provided by the client
    * Any external API or database calls made
    * Expected vs. actual inputs/outputs
    * Any domain-specific logic that determines success or failure

  Because of this, errors can be classified and contextualized
  before they propagate further. For example, if an API request fails,
  the resolver can distinguish between:

    * A user error (e.g., invalid input)
    * A transient network failure (e.g., timeout)
    * A critical system issue (e.g., an unavailable service)

  This classification is essential for meaningful error reporting and
  debugging.

  Middleware on the other hand execute after the resolver has returned
  a response, meaning it only sees the final result—either a successful
  value or an error. This creates a few key problems:

    * Loss of Context – Middleware does not know how the error occurred,
      which inputs were used, or what external calls were made.

    * Harder Debugging – Without direct access to resolver logic,
      tracing errors back to their source requires additional logging
      or metadata.

    * Inflexibility – Middleware can apply generic transformations to
      errors (e.g., converting internal errors to user-friendly
      messages), but it cannot intelligently categorize errors without
      resolver-level details.

    * This makes middleware behave like a black box, applying broad
      error-handling rules without fully understanding the underlying
      issue.

  The approach this API takes is to:

    1. Handle and classify errors in resolvers – Ensure that errors
      include enough context before they leave the resolver.

    2. Use middleware for formatting and standardization – Middleware
      should structure errors into a consistent GraphQL response format
      but not be responsible for determining their meaning.

  For example:

  ```elixir
  defmodule MyAppWeb.UserResolver do
    alias GraphQLShorts.CommonChangeset

    def create_user(%{input: input} = args, _resolution) do
      case MyApp.create_user(%{email: input.email}) do
        {:ok, user} ->
          {:ok, %{user: user}}

        {:error, e} ->
          GraphQLShorts.CommonErrors.translate_error(e,
            {
              %{is_struct: Ecto.Changeset, data: %{is_struct: MyApp.User}},
              fn changeset ->
                CommonChangeset.convert_to_graphql_user_errors(
                  changeset,
                  input,
                  keys: [:email]
                )
              end
            }
          )
      end
    end
  end
  ```

  ## Getting Started

  The Absinthe API is split into the following components:

    - `GraphQLShorts.Absinthe.Middleware`
    - `GraphQLShorts.Absinthe.Types`

  ## Getting Started

  Add the `absinthe` dependency to `mix.exs`:

  ```elixir
  def deps do
    [
      {:absinthe, "~> 1.0"}
    ]
  end
  ```

  Download the dependency:

  ```sh
  > mix.deps.get
  ```

  Now you can add the types and middleware:

    - `GraphQLShorts.Absinthe.Types`
    - `GraphQLShorts.Absinthe.Middleware`
  """
end
