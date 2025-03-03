if Code.ensure_loaded?(Absinthe) do
  defmodule GraphQLShorts.Absinthe.ResolutionHelpers do
    @moduledoc """
    Helper functions for `Absinthe.Resolution`.

    ## Getting Started

    Add the `absinthe` dependency to `mix.exs`:

    ```elixir
    def deps do
      [
        {:absinthe, "~> 1.7"}
      ]
    end
    ```
    """

    @type object_type :: :query | :mutation | :subscription

    @doc """
    Returns the type `:query`, `:mutation`, or `:subscription` given
    an `Absinthe.Resolution` struct.

    ### Examples

        iex> GraphQLShorts.Absinthe.ResolutionHelpers.operation_type(%Absinthe.Resolution{parent_type: %Absinthe.Type.Object{identifier: :query}})
        :query

        iex> GraphQLShorts.Absinthe.ResolutionHelpers.operation_type(%Absinthe.Resolution{parent_type: %Absinthe.Type.Object{name: "RootQueryType"}})
        :query

        iex> GraphQLShorts.Absinthe.ResolutionHelpers.operation_type(%Absinthe.Resolution{parent_type: %Absinthe.Type.Object{identifier: :mutation}})
        :mutation

        iex> GraphQLShorts.Absinthe.ResolutionHelpers.operation_type(%Absinthe.Resolution{parent_type: %Absinthe.Type.Object{name: "RootMutationType"}})
        :mutation

        iex> GraphQLShorts.Absinthe.ResolutionHelpers.operation_type(%Absinthe.Resolution{parent_type: %Absinthe.Type.Object{identifier: :subscription}})
        :subscription

        iex> GraphQLShorts.Absinthe.ResolutionHelpers.operation_type(%Absinthe.Resolution{parent_type: %Absinthe.Type.Object{name: "RootSubscriptionType"}})
        :subscription
    """
    @spec operation_type(resolution :: map()) :: object_type()
    def operation_type(%{parent_type: %{identifier: :query}} = _res), do: :query
    def operation_type(%{parent_type: %{name: "RootQueryType"}} = _res), do: :query

    def operation_type(%{parent_type: %{identifier: :mutation}} = _res), do: :mutation
    def operation_type(%{parent_type: %{name: "RootMutationType"}} = _res), do: :mutation

    def operation_type(%{parent_type: %{identifier: :subscription}} = _res), do: :subscription
    def operation_type(%{parent_type: %{name: "RootSubscriptionType"}} = _res), do: :subscription
  end
end
