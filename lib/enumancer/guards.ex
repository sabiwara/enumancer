defmodule Enumancer.Guards do
  @spec validate_positive_integer(integer()) :: integer()
  def validate_positive_integer(int) when is_integer(int) and int >= 0, do: int

  @spec validate_binary(binary()) :: binary()
  def validate_binary(binary) when is_binary(binary), do: binary
end
