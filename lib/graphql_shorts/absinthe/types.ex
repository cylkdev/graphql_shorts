if Code.ensure_loaded?(Absinthe) do
  defmodule GraphQLShorts.Absinthe.Types do
    @moduledoc """
    # GraphQLShorts.Absinthe.Types

    This module provides absinthe types for `GraphQLShorts.Absinthe.Middleware`.

    ## How to Use

    Import the types from this module in your absinthe schema:

    ```elixir
    defmodule MyAppWeb.Schema do
      use Absinthe.Schema

      # Adds the type :user_error
      import_types GraphQLShorts.Absinthe.Types
    end
    ```
    """
    use Absinthe.Schema.Notation

    object :user_error do
      field :field, list_of(:string)
      field :message, :string
    end

    defmacro user_errors do
      quote do
        field :user_errors, list_of(:user_error)
      end
    end
  end
end
