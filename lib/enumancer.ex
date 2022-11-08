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

  ##############
  ## Filtering
  ##############

  @doc """
  .

  ## Examples

      iex> E.filter(1..4, &rem(&1, 2) == 1)
      [1, 3]

  """
  def_enum filter(enumerable, fun)

  @doc """
  .

  ## Examples

      iex> E.reject(1..4, &rem(&1, 2) == 1)
      [2, 4]

  """
  def_enum reject(enumerable, fun)

  @doc """
  .

  ## Examples

      iex> E.split_with(1..4, &rem(&1, 2) == 1)
      {[1, 3], [2, 4]}

  """
  def_enum split_with(enumerable, fun)

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

      iex> E.split(1..10, 5)
      {[1, 2, 3, 4, 5], [6, 7, 8, 9, 10]}

  """
  def_enum split(enumerable, amount)

  @doc """
  .

  ## Examples

      iex> E.take_while(1..1000, & &1 < 6)
      [1, 2, 3, 4, 5]

  """
  def_enum take_while(enumerable, fun)

  @doc """
  .

  ## Examples

      iex> E.drop_while(1..10, & &1 < 6)
      [6, 7, 8, 9, 10]

  """
  def_enum drop_while(enumerable, fun)

  @doc """
  .

  ## Examples

      iex> E.split_while(1..10, & &1 < 6)
      {[1, 2, 3, 4, 5], [6, 7, 8, 9, 10]}

  """
  def_enum split_while(enumerable, fun)

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

      iex> E.uniq_by([{1, :x}, {2, :y}, {1, :z}], fn {x, _} -> x end)
      [{1, :x}, {2, :y}]

  """
  def_enum uniq_by(enumerable, fun)

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

      iex> E.dedup_by([{1, :a}, {2, :b}, {2, :c}, {1, :a}], fn {x, _} -> x end)
      [{1, :a}, {2, :b}, {1, :a}]

  """
  def_enum dedup_by(enumerable, fun)

  ##############
  ## Reducers
  ##############

  @doc """
  .

  ## Examples

      iex> E.reduce(1..5, 1, &*/2)
      120

  """
  def_enum reduce(enumerable, acc, fun)

  @doc """
  .

  ## Examples

      iex> {:ok, pid} = Agent.start(fn -> [] end)
      iex> E.each(1..5, fn i -> Agent.update(pid, &[i | &1]) end)
      :ok
      iex> Agent.get(pid, & &1)
      [5, 4, 3, 2, 1]

  """
  def_enum each(enumerable, fun)

  @doc """
  .

  ## Examples

      iex> E.count([1, 2, 3])
      3

  """
  def_enum count(enumerable)

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

      iex> E.product(1..3)
      6

  """
  def_enum product(enumerable)

  @doc """
  .

  ## Examples

      iex> E.mean(1..10)
      5.5

  """
  def_enum mean(enumerable)

  @doc """
  .

  ## Examples

      iex> E.frequencies([1, 1, 2, 1, 2, 3])
      %{1 => 3, 2 => 2, 3 => 1}

  """
  def_enum frequencies(enumerable)

  @doc """
  .

  ## Examples

      iex> E.frequencies_by(~w{aa aA bb cc}, &String.downcase/1)
      %{"aa" => 2, "bb" => 1, "cc" => 1}

  """
  def_enum frequencies_by(enumerable, fun)

  @doc """
  .

  ## Examples

      iex> E.group_by(~w{ant buffalo cat dingo}, &String.length/1)
      %{3 => ["cat", "ant"], 5 => ["dingo"], 7 => ["buffalo"]}

  """
  def_enum group_by(enumerable, key_fun)

  @doc """
  .

  ## Examples

      iex> E.group_by(~w{ant buffalo cat dingo}, &String.length/1, &String.first/1)
      %{3 => ["c", "a"], 5 => ["d"], 7 => ["b"]}

  """
  def_enum group_by(enumerable, key_fun, value_fun)

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

  ##############
  ## Find/exist
  ##############

  @doc """
  .

  ## Examples

      iex> E.empty?([])
      true

      iex> E.empty?([:foo])
      false

  """
  def_enum empty?(enumerable)

  @doc """
  .

  ## Examples

      iex> E.any?([false, true])
      true

      iex> E.any?([false, nil])
      false

      iex> E.any?([])
      false

  """
  def_enum any?(enumerable)

  @doc """
  .

  ## Examples

      iex> E.all?(["yes", true])
      true

      iex> E.all?([false, true])
      false

      iex> E.all?([])
      true

  """
  def_enum all?(enumerable)

  ##############
  ## Position
  ##############

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

  ##############
  ## Wrappers
  ##############

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

      iex> E.sort([4, 1, 5, 2, 3], :desc)
      [5, 4, 3, 2, 1]

  """
  def_enum sort(enumerable, sorter)

  @doc """
  .

  ## Examples

      iex> E.sort_by(["some", "kind", "of", "monster"], &byte_size/1)
      ["of", "kind", "some", "monster"]

  """
  def_enum sort_by(enumerable, fun)

  ##############
  ## Flattening
  ##############

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
    # |> E.take(-5)
    |> E.sum()
  end
end
