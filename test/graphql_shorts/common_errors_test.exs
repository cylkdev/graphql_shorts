defmodule GraphQLShorts.CommonErrorsTest do
  use ExUnit.Case, async: true
  doctest GraphQLShorts.CommonErrors

  describe "handle_error_response" do
    test "handles error response" do
      assert {:error,
              [
                %GraphQLShorts.TopLevelError{
                  code: :im_a_teapot,
                  message: "i'm not a teapot",
                  extensions: %{documentation: "https://api.com/docs"}
                }
              ]} =
               GraphQLShorts.CommonErrors.handle_error_response(
                 {:error, %{code: :im_a_teapot, message: "i'm a teapot"}},
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
