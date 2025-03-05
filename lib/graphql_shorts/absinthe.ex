defmodule GraphQLShorts.Absinthe do
  @moduledoc """
  # GraphQLShorts.Absinthe

  ## Installation

  Add the `absinthe` dependency to `mix.exs`:

  ```elixir
  def deps do
    [
      {:absinthe, "~> 1.0"}
    ]
  end
  ```

  Run `mix deps.get` to download the dependency.

  ## Introduction

  Error handling in `Absinthe` is typically done in resolvers or
  in Middleware. While middleware can standardize error
  responses, handling errors inside resolvers is often more
  effective because it preserves crucial contextual information.
  Middleware, on the other hand, operates at a higher level of
  abstraction, which may not give us enough important details.

  Resolvers have direct access to all relevant execution details
  at the moment an error occurs, including:

    * The query arguments provided by the client.
    * Any API or database calls made.
    * Expected vs. actual inputs/outputs.
    * Any domain-specific logic that determines success or failure.

  This allows us to categorize and translate error messages in
  our application before they propagate further. For example, if
  an API request fails, the resolver can distinguish between:

    * A user error (e.g. invalid input)
    * A transient network failure (e.g. timeout)
    * A critical system issue (e.g. an unavailable service)

  This allows the responsibility of error handling, reporting,
  and debugging to be handled in one place. Middleware, on the
  other hand, executes after the resolver has returned a response
  and only sees a successful value or an error.

  This creates a few key problems:

    * **Loss of Context** – Middleware does not know how the error
      occurred, which inputs were used, or what API calls were made.

    * **Harder To Debug** – Without direct access to resolver logic,
      tracing errors back to their source requires additional
      logging or metadata.

    * **Loss of Flexibility** – Middleware can apply generic
      transformations to errors (e.g. converting internal errors to
      user-friendly messages), but it cannot intelligently categorize
      errors without resolver-level details.

  This makes middleware behave like a black box, applying broad
  error-handling rules without fully understanding the underlying
  issue.

  The approach of this API is to:

    1. **Handle and classify errors in resolvers** – Ensure that
      errors include enough context before they leave the resolver.

    2. **Use middleware for formatting and standardization** –
      Middleware should structure errors into a consistent GraphQL
      response format but not be responsible for determining their
      meaning.

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
                CommonChangeset.translate_changeset_errors(
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

  This API is split into the following components:

    - `GraphQLShorts.Absinthe.Types`
    - `GraphQLShorts.Absinthe.Middleware`
  """
end
