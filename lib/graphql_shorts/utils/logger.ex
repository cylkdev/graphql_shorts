defmodule GraphQLShorts.Utils.Logger do
  @moduledoc false
  require Logger

  @doc false
  @spec debug(identifier :: binary(), message :: binary()) :: :ok
  def debug(identifier, message) do
    identifier
    |> format_message(message)
    |> Logger.debug()
  end

  @doc false
  @spec info(identifier :: binary(), message :: binary()) :: :ok
  def info(identifier, message) do
    identifier
    |> format_message(message)
    |> Logger.info()
  end

  @doc false
  @spec warning(identifier :: binary(), message :: binary()) :: :ok
  if Code.ensure_loaded?(:logger) and function_exported?(:logger, :warning, 2) do
    def warning(identifier, message) do
      identifier
      |> format_message(message)
      |> Logger.warning()
    end
  else
    def warning(identifier, message) do
      identifier
      |> format_message(message)
      |> Logger.warn()
    end
  end

  @doc false
  @spec error(identifier :: binary(), message :: binary()) :: :ok
  def error(identifier, message) do
    identifier
    |> format_message(message)
    |> Logger.error()
  end

  defp format_message(identifier, message) do
    "[#{identifier}] #{message}"
  end
end
