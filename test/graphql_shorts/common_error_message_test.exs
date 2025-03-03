defmodule GraphQLShorts.CommonErrorMessageTest do
  use ExUnit.Case, async: true
  doctest GraphQLShorts.CommonErrorMessage

  alias GraphQLShorts.CommonErrorMessage

  describe "&translate_error/3" do
    test "returns expected changes with :resolve option" do
      assert [
               %GraphQLShorts.TopLevelError{
                 message: "changed_message",
                 code: "CHANGED_CODE",
                 extensions: %{documentation: "https://api.myapp.com/docs"}
               }
             ] =
               CommonErrorMessage.translate_error(
                 %ErrorMessage{
                   code: :service_unavailable,
                   message: "Service unavailable, Please try again later.",
                   details: nil
                 },
                 :mutation,
                 resolve: fn %{
                               code: :service_unavailable,
                               message: "Service unavailable, Please try again later.",
                               extensions: %{}
                             } ->
                   %{
                     code: "CHANGED_CODE",
                     message: "changed_message",
                     extensions: %{documentation: "https://api.myapp.com/docs"}
                   }
                 end
               )
    end

    test "returns mutation top-level error" do
      assert [
               %GraphQLShorts.TopLevelError{
                 message: "Service unavailable, Please try again later.",
                 code: :service_unavailable,
                 extensions: %{extra: "information"}
               }
             ] =
               CommonErrorMessage.translate_error(
                 %ErrorMessage{
                   code: :service_unavailable,
                   message: "Service unavailable, Please try again later.",
                   details: %{extra: "information"}
                 },
                 :mutation
               )
    end

    test "returns mutation user error" do
      assert [
               %GraphQLShorts.UserError{
                 field: [:input, :id],
                 message: "You do not have permission to access this resource."
               }
             ] =
               CommonErrorMessage.translate_error(
                 %ErrorMessage{
                   code: :forbidden,
                   message: "You do not have permission to access this resource.",
                   details: %{extra: "information"}
                 },
                 :mutation,
                 %{field: [:input, :id]}
               )
    end

    test "returns query top-level error" do
      assert [
               %GraphQLShorts.TopLevelError{
                 message: "Too many requests, Please try again later.",
                 code: :too_many_requests,
                 extensions: extensions
               }
             ] =
               CommonErrorMessage.translate_error(
                 %ErrorMessage{
                   code: :too_many_requests,
                   message: "Too many requests, Please try again later.",
                   details: %{}
                 },
                 :query
               )

      assert %{} === extensions
    end
  end
end
