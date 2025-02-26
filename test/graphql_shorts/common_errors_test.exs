defmodule GraphQLShorts.CommonErrorsTest do
  use ExUnit.Case, async: true
  doctest GraphQLShorts.CommonErrors

  describe "handle_error_response" do
    test "handles error response" do
      assert {:error, %{code: :im_a_teapot, message: "i'm not a teapot"}} =
               GraphQLShorts.CommonErrors.handle_error_response(
                 {:error, %{code: :im_a_teapot, message: "i'm a teapot"}},
                 %{code: :im_a_teapot},
                 fn e -> %{e | message: "i'm not a teapot"} end
               )
    end
  end
end
