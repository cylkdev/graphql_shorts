defmodule GraphQLShorts.Utils.LoggerTest do
  use ExUnit.Case
  doctest GraphQLShorts.Utils.Logger

  import ExUnit.CaptureLog

  @logger_prefix "GraphQLShorts.Utils.LoggerTest"

  test "debug" do
    assert capture_log([level: :debug], fn ->
             GraphQLShorts.Utils.Logger.debug(@logger_prefix, "debug")
           end) =~ "debug"
  end

  test "info" do
    assert capture_log([level: :info], fn ->
             GraphQLShorts.Utils.Logger.info(@logger_prefix, "info")
           end) =~ "info"
  end

  test "warning" do
    assert capture_log([level: :warning], fn ->
             GraphQLShorts.Utils.Logger.warning(@logger_prefix, "warning")
           end) =~ "warning"
  end

  test "error" do
    assert capture_log([level: :error], fn ->
             GraphQLShorts.Utils.Logger.error(@logger_prefix, "error")
           end) =~ "error"
  end
end
