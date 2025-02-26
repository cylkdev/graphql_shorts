defmodule GraphQLShorts do
  @moduledoc """
  `GraphQLShorts` focuses on making GraphQL APIs easier to write and
  maintain with shorter code.

  This API is split into the following main components:

    - `GraphQLShorts.CommonErrors` - Provides error handling functionality.
      Use data to convert errors to top-level errors or user errors.

  ```elixir
  defmodule MyAppWeb.UserResolver do
    alias GraphQLShorts.Bridges.ChangesetBridge

    def create_user(%{input: input} = args, _resolution) do
      response =
        {:error, %Ecto.Changeset{
          changes: %{},
          data: %MyApp.Schemas.User{},
          errors: [email: {"can't be blank", [validation: :required]}]
        }}

      conditions = %{is_struct: Ecto.Changeset}

      error_fun =
        fn changeset ->
          ChangesetBridge.build_user_errors(
            changeset,
            args,
            [
              path: [:input],
              mappings: [:email]
            ]
          )
        end

      GraphQLShorts.CommonErrors.handle_error_response(response, conditions, error_fun)
    end
  end
  ```
  """
end
