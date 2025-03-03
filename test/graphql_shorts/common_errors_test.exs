defmodule GraphQLShorts.CommonErrorsTest do
  use ExUnit.Case, async: true
  doctest GraphQLShorts.CommonErrors

  describe "translate_error" do
    test "handles error response" do
      assert [
               %GraphQLShorts.TopLevelError{
                 code: :im_a_teapot,
                 message: "i'm not a teapot",
                 extensions: %{documentation: "https://api.com/docs"}
               }
             ] =
               GraphQLShorts.CommonErrors.translate_error(
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
