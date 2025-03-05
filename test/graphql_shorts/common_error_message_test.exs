defmodule GraphQLShorts.CommonErrorMessageTest do
  use ExUnit.Case, async: true
  doctest GraphQLShorts.CommonErrorMessage

  alias GraphQLShorts.CommonErrorMessage

  describe "&translate_error/3" do
    test "can add details to extensions when resolver is :none and option :show_sensitive_info is true" do
      error =
        %ErrorMessage{
          code: :service_unavailable,
          message: "service_unavailable_message",
          details: %{extra: "information"}
        }

      assert [%GraphQLShorts.TopLevelError{extensions: %{extra: "information"}}] =
               CommonErrorMessage.translate_error(error, :mutation, :none,
                 show_sensitive_info: true
               )
    end

    test "returns top-level error when operation is :mutation and code is :service_unavailable" do
      error_message =
        %ErrorMessage{
          code: :service_unavailable,
          message: "service_unavailable_message",
          details: nil
        }

      resolver =
        fn
          %{
            code: :service_unavailable,
            message: "service_unavailable_message",
            details: nil
          },
          %{
            operation: :mutation,
            error_type: :top_level
          } ->
            %{
              code: "SERVICE_UNAVAILABLE",
              message: "service_unavailable_message",
              extensions: %{documentation: "https://api.myapp.com/docs"}
            }
        end

      assert [
               %GraphQLShorts.TopLevelError{
                 message: "service_unavailable_message",
                 code: "SERVICE_UNAVAILABLE",
                 extensions: %{documentation: "https://api.myapp.com/docs"}
               }
             ] = CommonErrorMessage.translate_error(error_message, :mutation, resolver)
    end

    test "returns user error when operation is :mutation and code is :forbidden" do
      error =
        %ErrorMessage{
          code: :forbidden,
          message: "forbidden_message",
          details: %{extra: "information"}
        }

      resolver =
        fn
          %{
            code: :forbidden,
            message: "forbidden_message",
            details: %{extra: "information"}
          },
          %{
            operation: :mutation,
            error_type: :user_error
          } ->
            %{
              message: "forbidden_message",
              field: [:input, :id]
            }
        end

      assert [
               %GraphQLShorts.UserError{
                 field: [:input, :id],
                 message: "forbidden_message"
               }
             ] = CommonErrorMessage.translate_error(error, :mutation, resolver)
    end

    test "returns query top-level error for user induced error code :too_many_requests" do
      error =
        %ErrorMessage{
          code: :too_many_requests,
          message: "too_many_requests_message",
          details: nil
        }

      assert [
               %GraphQLShorts.TopLevelError{
                 message: "too_many_requests_message",
                 code: :too_many_requests,
                 extensions: %{}
               }
             ] = CommonErrorMessage.translate_error(error, :query)
    end

    test "returns query top-level error for user induced error code :forbidden" do
      error =
        %ErrorMessage{
          code: :forbidden,
          message: "forbidden_message",
          details: nil
        }

      assert [
               %GraphQLShorts.TopLevelError{
                 message: "forbidden_message",
                 code: :forbidden,
                 extensions: %{}
               }
             ] = CommonErrorMessage.translate_error(error, :query)
    end

    test "can convert a list of error messages" do
      error =
        %ErrorMessage{
          code: :internal_server_error,
          message: "internal_server_error_message",
          details: nil
        }

      assert [
               %GraphQLShorts.TopLevelError{
                 message: "internal_server_error_message",
                 code: :internal_server_error,
                 extensions: %{}
               },
               %GraphQLShorts.TopLevelError{
                 message: "internal_server_error_message",
                 code: :internal_server_error,
                 extensions: %{}
               }
             ] = CommonErrorMessage.translate_error([error, error], :query)
    end
  end
end
