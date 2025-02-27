# defmodule GraphQLShorts.Bridges.ErrorMessageBridgeTest do
#   use ExUnit.Case, async: true
#   doctest GraphQLShorts.Bridges.ErrorMessageBridge

#   alias GraphQLShorts.Bridges.ErrorMessageBridge

#   describe "" do
#     test "" do
#       # ...
#       error =
#         %ErrorMessage{
#           code: :forbidden,
#           message: "You don't have permission to access this resource.",
#           details: %{
#             params: %{
#               id: 1,
#               user: %{
#                 email: "example@test.com"
#               }
#             }
#           }
#         }

#       # mutation arguments
#       arguments =
#         %{
#           input: %{
#             id: 1,
#             user: %{
#               email: "example@test.com"
#             }
#           }
#         }

#       schema =
#         [
#           path: [:input],
#           mappings: [
#             :id,
#             user: [
#               keys: [
#                 email: [
#                   field: :email
#                 ]
#               ]
#             ]
#           ]
#         ]

#     end
#   end
# end
