defmodule V2 do
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

      iex> E.map(1..99999999, & &1 * &1) |> E.take(5) |> E.explain()
      [1, 4, 9, 16, 25]

  """

  import V2.Core

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

  ## Examples

      iex> E.take(1..1000, 5)
      [1, 2, 3, 4, 5]

  Negative indexes are **NOT** supported, since this would imply to
  load the whole list and therefore cannot be done lazily.

      iex> E.take(1..1000, -5)
      ** (CaseClauseError) no case clause matching: -5

  """
  def_enum take(enumerable, amount)

  @doc """
  .

  ## Examples

      iex> E.drop(1..10, 5)
      [6, 7, 8, 9, 10]

  """
  def_enum drop(enumerable, amount)

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

  defmacro def(foo, bar) do
    Macro.to_string([foo, bar])
  end

  defmacro explain(expr) do
    Macro.expand(expr, __CALLER__) |> inspect_ast()
  end
end

defmodule V2.Sample do
  require V2, as: E

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
