defmodule Enumancer do
  @moduledoc """

  ## Examples

      iex> E.map([1, 2, 3], & &1 * &1)
      [1, 4, 9]

      iex> E.map(1..3, & &1 * &1)
      [1, 4, 9]

      iex> 1..3 |> E.map(& &1 * &1) |> E.sum()
      14

      iex> E.sum(E.map(1..3, & &1 * &1))
      14

      iex> "abc" |> String.graphemes() |> E.map(& &1 <> &1) |> E.join() |> String.upcase()
      "AABBCC"

      iex> "abc" |> String.graphemes() |> E.map(& &1 <> &1) |> E.join("-") |> String.upcase()
      "AA-BB-CC"

      iex> E.map(-5..6, &abs/1) |> E.uniq()
      [5, 4, 3, 2, 1, 0, 6]

      iex> E.map(-5..6, &abs/1) |> E.uniq() |> E.filter(& &1 > 2)
      [5, 4, 3, 6]

      iex> E.map(1..99999999, & &1 * &1) |> E.take(5)
      [1, 4, 9, 16, 25]

  """

  import Enumancer.Core
  import Enumancer.MacroHelpers

  @doc """
  .

  ## Examples

      iex> E.map(1..3, & &1 * &1)
      [1, 4, 9]

  """
  def_enum map(enumerable, fun)

  @doc """
  .

  ## Examples

      iex> E.filter(1..3, &rem(&1, 2) == 1)
      [1, 3]

  """
  def_enum filter(enumerable, fun)

  @doc """
  .

  ## Examples

      iex> E.sum(1..3)
      6

  """
  def_enum sum(enumerable)

  @doc """
  .

  ## Examples

      iex> E.join(1..3)
      "123"

  """
  def_enum join(enumerable)

  @doc """
  .

  ## Examples

      iex> E.join(1..3, "-")
      "1-2-3"

  """
  def_enum join(enumerable, joiner)

  @doc """
  .

  ## Examples

      iex> E.uniq([1, 2, 1, 3, 2, 4])
      [1, 2, 3, 4]

  """
  def_enum uniq(enumerable)

  @doc """
  .

  ## Examples

      iex> E.dedup([1, 2, 2, 3, 3, 1, 3])
      [1, 2, 3, 1, 3]

  """
  def_enum dedup(enumerable)

  @doc """
  .

  Negative indexes are **NOT** supported, since this would imply to
  load the whole list and therefore cannot be done lazily.

  ## Examples

      iex> E.take(1..1000, 5)
      [1, 2, 3, 4, 5]

  """
  def_enum take(enumerable, amount)

  @doc """
  .

  Negative indexes are **NOT** supported, since this would imply to
  load the whole list and therefore cannot be done lazily.

  ## Examples

      iex> E.drop(1..10, 5)
      [6, 7, 8, 9, 10]

  """
  def_enum drop(enumerable, amount)

  @doc """
  .

  Negative indexes are **NOT** supported, since this would imply to
  load the whole list and therefore cannot be done lazily.

  ## Examples

      iex> E.at(1..1000, 5)
      6
      iex> E.at(1..1000, 1000)
      nil

  """
  def_enum at(enumerable, index)

  @doc """
  .

  Negative indexes are **NOT** supported, since this would imply to
  load the whole list and therefore cannot be done lazily.

  ## Examples

      iex> E.at(1..1000, 5, :none)
      6
      iex> E.at(1..1000, 1000, :none)
      :none

  """
  def_enum at(enumerable, index, default)

  @doc """
  .

  ## Examples

      iex> E.first(1..1000)
      1
      iex> E.first([])
      nil

  """
  def_enum first(enumerable)

  @doc """
  .

  ## Examples

      iex> E.first(1..10, :none)
      1
      iex> E.first([], :none)
      :none

  """
  def_enum first(enumerable, default)

  @doc """
  .

  ## Examples

      iex> E.last(1..10)
      10
      iex> E.last([])
      nil

  """
  def_enum last(enumerable)

  @doc """
  .

  ## Examples

      iex> E.last(1..10, :none)
      10
      iex> E.last([], :none)
      :none

  """
  def_enum last(enumerable, default)

  @doc """
  .

  ## Examples

      iex> E.reverse(1..3)
      [3, 2, 1]

  """
  def_enum reverse(enumerable)

  @doc """
  .

  ## Examples

      iex> E.reverse(1..3, 4..6)
      [3, 2, 1, 4, 5, 6]

  """
  def_enum reverse(enumerable, tail)

  @doc """
  .

  ## Examples

      iex> E.sort([4, 1, 5, 2, 3])
      [1, 2, 3, 4, 5]

  """
  def_enum sort(enumerable)

  @doc """
  .

  ## Examples

      iex> E.concat([1..3, 4..6])
      [1, 2, 3, 4, 5, 6]

  """
  def_enum concat(enumerable)

  @doc """
  .

  ## Examples

      iex> E.flat_map(1..3, fn n -> 1..n end)
      [1, 1, 2, 1, 2, 3]

  """
  def_enum flat_map(enumerable, fun)

  defmacro def(foo, bar) do
    Macro.to_string([foo, bar])
  end

  defmacro explain(expr) do
    Macro.expand(expr, __CALLER__) |> inspect_ast()
  end
end

defmodule Enumancer.Sample do
  require Enumancer, as: E

  E.def sum_squares(enumerable) do
    enumerable
    |> E.map(&(&1 * &1))
    |> E.sum()
  end

  def sum_squares2(enumerable) do
    enumerable
    |> E.map(&(&1 * &1))
    |> E.take(-5)
    |> E.sum()
  end
end
