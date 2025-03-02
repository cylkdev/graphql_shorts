defmodule GraphQLShorts.CommonErrorHandlerTest do
  use ExUnit.Case, async: true
  doctest GraphQLShorts.CommonErrorHandler

  describe "convert_to_error_message" do
    test "handles error response" do
      assert [
               %GraphQLShorts.TopLevelError{
                 code: :im_a_teapot,
                 message: "i'm not a teapot",
                 extensions: %{documentation: "https://api.com/docs"}
               }
             ] =
               GraphQLShorts.CommonErrorHandler.convert_to_error_message(
                 %{code: :im_a_teapot, message: "i'm a teapot"},
                 {
                   %{code: :im_a_teapot},
                   fn %{code: :im_a_teapot} ->
                     GraphQLShorts.TopLevelError.create(
                       code: :im_a_teapot,
                       message: "i'm not a teapot",
                       extensions: %{
                         documentation: "https://api.com/docs"
                       }
                     )
                   end
                 }
               )
    end
  end
end
