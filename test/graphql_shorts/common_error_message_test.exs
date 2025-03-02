defmodule GraphQLShorts.CommonErrorMessageTest do
  use ExUnit.Case, async: true
  doctest GraphQLShorts.CommonErrorMessage

  alias GraphQLShorts.CommonErrorMessage

  describe "&translate_error_message/3" do
    test "returns mutation top-level error" do
      assert %GraphQLShorts.TopLevelError{
               message: "Service unavailable.",
               code: :service_unavailable,
               extensions: %{documentation: "https://api.myapp.com/docs"}
             } =
               CommonErrorMessage.translate_error_message(
                 :mutation,
                 %{code: :service_unavailable, message: "Service unavailable."},
                 %{extensions: %{documentation: "https://api.myapp.com/docs"}}
               )
    end

    test "returns mutation user error" do
      assert %GraphQLShorts.UserError{
               field: [:input, :id],
               message: "You do not have permission to access this resource."
             } =
               CommonErrorMessage.translate_error_message(
                 :mutation,
                 %{
                   code: :forbidden,
                   message: "You do not have permission to access this resource."
                 },
                 %{
                   field: [:input, :id],
                   code: "INSUFFICIENT_PERMISSION",
                   extensions: %{
                     id: 1,
                     documentation: "https://api.myapp.com/docs"
                   }
                 }
               )
    end

    test "returns query top-level error" do
      assert %GraphQLShorts.TopLevelError{
               message: "Too many requests, Please try again later.",
               code: :too_many_requests,
               extensions: extensions
             } =
               CommonErrorMessage.translate_error_message(
                 :query,
                 %{
                   code: :too_many_requests,
                   message: "Too many requests, Please try again later."
                 }
               )

      assert %{} === extensions
    end

    test "returns query field specific error" do
      assert %GraphQLShorts.TopLevelError{
               message: "You do not have permission to access this resource.",
               code: :forbidden,
               extensions: extensions
             } =
               CommonErrorMessage.translate_error_message(
                 :query,
                 %{
                   code: :forbidden,
                   message: "You do not have permission to access this resource."
                 },
                 %{field: [:input, :id]}
               )

      assert %{field: [:input, :id]} === extensions
    end
  end
end
