defmodule GraphQLShorts.Bridges.ErrorMessageBridgeTest do
  use ExUnit.Case, async: true
  doctest GraphQLShorts.Bridges.ErrorMessageBridge

  alias GraphQLShorts.Bridges.ErrorMessageBridge

  describe "" do
    test "" do
      # ...
      error =
        %ErrorMessage{
          code: :forbidden,
          message: "You don't have permission to access this resource.",
          details: %{
            params: %{
              id: 1,
              user: %{
                email: "example@test.com"
              }
            }
          }
        }

      # mutation arguments
      arguments =
        %{
          input: %{
            id: 1,
            user: %{
              email: "example@test.com"
            }
          }
        }

      schema =
        [
          operation: :mutation,
          keys: [
            title: [
              input_key: :title,
              resolve: fn message, field -> {message, field} end,
              keys: []
            ],
            comments: [
              input_key: :comments,
              resolve: fn message, field -> {message, field} end,
              keys: [
                body: [
                  input_key: :body,
                  resolve: fn message, field -> {message, field} end,
                  keys: []
                ]
              ]
            ]
          ]
        ]

    end
  end
end
