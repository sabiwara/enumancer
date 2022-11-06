defmodule EnumancerOldTest do
  use ExUnit.Case, async: true
  import EnumancerOld, warn: false
  doctest EnumancerOld

  describe "defenum" do
    test "map" do
      defmodule EnumancerOldTest.Map do
        defenum run(enum) do
          map(enum, &to_string/1)
        end
      end

      assert ["1", "2", "3"] = EnumancerOldTest.Map.run([1, 2, 3])
      assert ["1", "2", "3"] = EnumancerOldTest.Map.run(1..3)
    end

    test "filter" do
      defmodule EnumancerOldTest.Filter do
        defenum run(enum) do
          filter(enum, &(rem(&1, 2) == 1))
        end
      end

      assert [1, 3] = EnumancerOldTest.Filter.run([1, 2, 3])
      assert [1, 3] = EnumancerOldTest.Filter.run(1..3)
    end

    test "reduce/2" do
      defmodule EnumancerOldTest.Reduce2 do
        defenum run(enum) do
          reduce(enum, &+/2)
        end
      end

      assert 6 = EnumancerOldTest.Reduce2.run([1, 2, 3])
      assert 6 = EnumancerOldTest.Reduce2.run(1..3)

      assert_raise Enum.EmptyError, fn -> EnumancerOldTest.Reduce2.run([]) end
      assert_raise Enum.EmptyError, fn -> EnumancerOldTest.Reduce2.run(1..0//1) end
    end

    test "reduce/3" do
      defmodule EnumancerOldTest.Reduce3 do
        defenum run(enum) do
          reduce(enum, 0, &+/2)
        end
      end

      assert 6 = EnumancerOldTest.Reduce3.run([1, 2, 3])
      assert 6 = EnumancerOldTest.Reduce3.run(1..3)
    end

    test "map_reduce/3" do
      defmodule EnumancerOldTest.MapReduce do
        defenum run(enum) do
          map_reduce(enum, 0, fn x, acc -> {x * 2, x + acc} end)
        end
      end

      assert {[2, 4, 6], 6} = EnumancerOldTest.MapReduce.run([1, 2, 3])
      assert {[2, 4, 6], 6} = EnumancerOldTest.MapReduce.run(1..3)
    end

    test "max" do
      defmodule EnumancerOldTest.Max do
        defenum run(enum) do
          max(enum)
        end
      end

      assert 3 = EnumancerOldTest.Max.run([1, 3, 1, 2])
      assert 80 = EnumancerOldTest.Max.run(1..80)
      assert_raise Enum.EmptyError, fn -> EnumancerOldTest.Max.run([]) end
      assert_raise Enum.EmptyError, fn -> EnumancerOldTest.Max.run(1..0//1) end
    end

    test "max (module)" do
      defmodule EnumancerOldTest.MaxModule do
        defenum run(enum) do
          max(enum, Date)
        end
      end

      assert ~D[2022-01-01] =
               EnumancerOldTest.MaxModule.run([~D[2020-01-03], ~D[2022-01-01], ~D[2021-01-02]])
    end

    test "min" do
      defmodule EnumancerOldTest.Min do
        defenum run(enum) do
          min(enum)
        end
      end

      assert 1 = EnumancerOldTest.Min.run([1, 3, 1, 2])
      assert 1 = EnumancerOldTest.Min.run(1..80)
      assert_raise Enum.EmptyError, fn -> EnumancerOldTest.Min.run([]) end
      assert_raise Enum.EmptyError, fn -> EnumancerOldTest.Min.run(1..0//1) end
    end

    test "min (module)" do
      defmodule EnumancerOldTest.MinModule do
        defenum run(enum) do
          min(enum, Date)
        end
      end

      assert ~D[2020-01-03] =
               EnumancerOldTest.MinModule.run([~D[2020-01-03], ~D[2022-01-01], ~D[2021-01-02]])
    end

    test "sum" do
      defmodule EnumancerOldTest.Sum do
        defenum run(enum) do
          sum(enum)
        end
      end

      assert 6 = EnumancerOldTest.Sum.run([1, 2, 3])
      assert 6 = EnumancerOldTest.Sum.run(1..3)
    end

    test "product" do
      defmodule EnumancerOldTest.Product do
        defenum run(enum) do
          product(enum)
        end
      end

      assert 24 = EnumancerOldTest.Product.run([1, 2, 3, 4])
      assert 24 = EnumancerOldTest.Product.run(1..4)
    end

    test "join" do
      defmodule EnumancerOldTest.Join do
        defenum run(enum) do
          join(enum)
        end

        defenum run(enum, joiner) do
          join(enum, joiner)
        end
      end

      assert "123" = EnumancerOldTest.Join.run([1, 2, 3])
      assert "1-2-3" = EnumancerOldTest.Join.run([1, 2, 3], "-")
      assert "123" = EnumancerOldTest.Join.run(1..3)
      assert "1-2-3" = EnumancerOldTest.Join.run(1..3, "-")
    end

    test "uniq" do
      defmodule EnumancerOldTest.Uniq do
        defenum run(enum) do
          uniq(enum)
        end
      end

      assert [1, 2, 3] = EnumancerOldTest.Uniq.run([1, 2, 3, 3, 1])
      assert [1, 2, 3] = [1, 2, 3, 3, 1] |> Stream.map(& &1) |> EnumancerOldTest.Uniq.run()
    end

    test "uniq_by" do
      defmodule EnumancerOldTest.UniqBy do
        defenum run(enum) do
          uniq_by(enum, &div(&1, 3))
        end
      end

      assert [1, 3, 6] = EnumancerOldTest.UniqBy.run([1, 2, 3, 4, 5, 6, 7, 2, 1])
      assert [1, 3, 6] = EnumancerOldTest.UniqBy.run(1..7)
    end

    test "dedup" do
      defmodule EnumancerOldTest.Dedup do
        defenum run(enum) do
          dedup(enum)
        end
      end

      assert [1, 2, 3, 1] = EnumancerOldTest.Dedup.run([1, 2, 3, 3, 1, 1])
      assert [1, 2, 3, 1] = [1, 2, 3, 3, 1, 1] |> Stream.map(& &1) |> EnumancerOldTest.Dedup.run()
    end

    test "dedup_by" do
      defmodule EnumancerOldTest.DedupBy do
        defenum run(enum) do
          dedup_by(enum, &div(&1, 3))
        end
      end

      assert [1, 3, 6, 2] = EnumancerOldTest.DedupBy.run([1, 2, 3, 4, 5, 6, 7, 2, 1])
      assert [1, 3, 6] = EnumancerOldTest.DedupBy.run(1..7)
    end

    test "with_index" do
      defmodule EnumancerOldTest.WithIndex do
        defenum run(enum) do
          with_index(enum)
        end

        defenum run(enum, offset) do
          with_index(enum, offset)
        end
      end

      assert [a: 0, b: 1, c: 2] = EnumancerOldTest.WithIndex.run([:a, :b, :c])
      assert [a: 1, b: 2, c: 3] = EnumancerOldTest.WithIndex.run([:a, :b, :c], 1)
      assert [{100, 0}, {101, 1}, {102, 2}] = EnumancerOldTest.WithIndex.run(100..102)
      assert [{100, 1}, {101, 2}, {102, 3}] = EnumancerOldTest.WithIndex.run(100..102, 1)
    end

    test "drop" do
      defmodule EnumancerOldTest.Drop do
        defenum run(enum) do
          drop(enum, 1)
        end

        defenum run(enum, count) do
          drop(enum, count)
        end
      end

      assert [:b, :c, :d] = EnumancerOldTest.Drop.run([:a, :b, :c, :d])
      assert [2, 3, 4] = EnumancerOldTest.Drop.run(1..4)

      assert [:c, :d] = EnumancerOldTest.Drop.run([:a, :b, :c, :d], 2)
      assert [999, 1000] = EnumancerOldTest.Drop.run(1..1000, 998)

      assert_raise CaseClauseError, fn -> EnumancerOldTest.Drop.run([:a, :b, :c, :d], -1) end
      assert_raise CaseClauseError, fn -> EnumancerOldTest.Drop.run(1..1000, -1) end
    end

    test "scan" do
      defmodule EnumancerOldTest.Scan do
        defenum run(enum) do
          scan(enum, 0, &(&1 + &2))
        end
      end

      assert [1, 3, 6, 10, 15] = EnumancerOldTest.Scan.run([1, 2, 3, 4, 5])
      assert [1, 3, 6, 10, 15] = EnumancerOldTest.Scan.run(1..5)
    end

    test "map_reduce |> elem(0)" do
      defmodule EnumancerOldTest.MapReduceNoAcc do
        defenum run(enum) do
          enum |> map_reduce(0, &{{&1, &2}, &2 + 1}) |> elem(0)
        end
      end

      assert [a: 0, b: 1, c: 2] = EnumancerOldTest.MapReduceNoAcc.run([:a, :b, :c])
      assert [{100, 0}, {101, 1}, {102, 2}] = EnumancerOldTest.MapReduceNoAcc.run(100..102)
    end

    test "filter |> map" do
      defmodule EnumancerOldTest.FilterMap do
        defenum run(enum) do
          enum |> filter(&(rem(&1, 2) == 1)) |> map(&to_string/1)
        end
      end

      assert ["1", "3"] = EnumancerOldTest.FilterMap.run([1, 2, 3])
      assert ["1", "3"] = EnumancerOldTest.FilterMap.run(1..3)
    end

    test "map |> filter" do
      defmodule EnumancerOldTest.MapFilter do
        defenum run(enum) do
          enum |> map(&(&1 + 1)) |> filter(&(rem(&1, 2) == 1))
        end
      end

      assert [3, 5] = EnumancerOldTest.MapFilter.run([1, 2, 3, 4])
      assert [3, 5] = EnumancerOldTest.MapFilter.run(1..4)
    end

    test "filter |> reduce" do
      defmodule EnumancerOldTest.FilterReduce do
        defenum run(enum) do
          enum |> filter(&(rem(&1, 2) == 1)) |> reduce(0, &+/2)
        end
      end

      assert 4 = EnumancerOldTest.FilterReduce.run([1, 2, 3])
      assert 4 = EnumancerOldTest.FilterReduce.run(1..3)
    end

    test "map |> reverse" do
      defmodule EnumancerOldTest.MapReverse do
        defenum run(enum) do
          enum |> map(&(&1 * &1)) |> reverse()
        end

        defenum run(enum, list) do
          enum |> map(&(&1 * &1)) |> reverse(list)
        end
      end

      assert [9, 4, 1] = EnumancerOldTest.MapReverse.run([1, 2, 3])
      assert [9, 4, 1] = EnumancerOldTest.MapReverse.run(1..3)
      assert [9, 4, 1, 0] = EnumancerOldTest.MapReverse.run([1, 2, 3], [0])
      assert [9, 4, 1, 0] = EnumancerOldTest.MapReverse.run(1..3, [0])
    end

    test "map |> each" do
      defmodule EnumancerOldTest.FilterEach do
        defenum run(enum, fun) do
          enum |> filter(&(rem(&1, 2) == 1)) |> each(fun)
        end
      end

      {:ok, agent} = Agent.start(fn -> [] end)
      add = fn x -> Agent.update(agent, &[x | &1]) end

      assert :ok = EnumancerOldTest.FilterEach.run([1, 2, 3, 4], add)

      assert [3, 1] = Agent.get(agent, & &1)
    end

    test "reject |> count" do
      defmodule EnumancerOldTest.RejectCount do
        defenum run(enum) do
          enum |> reject(&(rem(&1, 2) == 1)) |> count()
        end
      end

      assert 2 = EnumancerOldTest.RejectCount.run([1, 2, 3, 4])
      assert 2 = EnumancerOldTest.RejectCount.run(1..4)
    end

    test "filter |> max" do
      defmodule EnumancerOldTest.FilterMax do
        defenum run(enum) do
          enum |> filter(&(rem(&1, 2) == 1)) |> max()
        end
      end

      assert 3 = EnumancerOldTest.FilterMax.run([1, 2, 3, 4])
      assert 3 = EnumancerOldTest.FilterMax.run(1..4)
      assert_raise Enum.EmptyError, fn -> EnumancerOldTest.FilterMax.run([2, 4]) end
      assert_raise Enum.EmptyError, fn -> EnumancerOldTest.FilterMax.run(2..4//2) end
    end

    test "filter |> sum" do
      defmodule EnumancerOldTest.FilterSum do
        defenum run(enum) do
          enum |> filter(&(rem(&1, 2) == 1)) |> sum()
        end
      end

      assert 4 = EnumancerOldTest.FilterSum.run([1, 2, 3])
      assert 4 = EnumancerOldTest.FilterSum.run(1..3)
    end

    test "filter |> join" do
      defmodule EnumancerOldTest.FilterJoin do
        defenum run(enum) do
          enum |> filter(&(rem(&1, 2) == 1)) |> join()
        end

        defenum run(enum, joiner) do
          enum |> filter(&(rem(&1, 2) == 1)) |> join(joiner)
        end
      end

      assert "13" = EnumancerOldTest.FilterJoin.run([1, 2, 3])
      assert "1-3" = EnumancerOldTest.FilterJoin.run([1, 2, 3], "-")
      assert "13" = EnumancerOldTest.FilterJoin.run(1..3)
      assert "1-3" = EnumancerOldTest.FilterJoin.run(1..3, "-")
    end

    test "map |> intersperse" do
      defmodule EnumancerOldTest.MapIntersperse do
        defenum run(enum) do
          enum |> map(&(&1 * &1)) |> intersperse(0)
        end
      end

      assert [1, 0, 4, 0, 9] = EnumancerOldTest.MapIntersperse.run([1, 2, 3])
      assert [1, 0, 4, 0, 9] = EnumancerOldTest.MapIntersperse.run(1..3)
    end

    test "map |> frequencies" do
      defmodule EnumancerOldTest.MapFrequencies do
        defenum run(enum) do
          enum |> map(&rem(&1, 3)) |> frequencies()
        end
      end

      assert %{0 => 1, 1 => 2, 2 => 2} = EnumancerOldTest.MapFrequencies.run([1, 2, 3, 4, 5])
      assert %{0 => 1, 1 => 2, 2 => 2} = EnumancerOldTest.MapFrequencies.run(1..5)
    end

    test "map |> frequencies_by" do
      defmodule EnumancerOldTest.MapFrequenciesBy do
        defenum run(enum) do
          enum |> map(&(&1 * &1)) |> frequencies_by(&rem(&1, 5))
        end
      end

      assert %{0 => 1, 1 => 2, 4 => 2} = EnumancerOldTest.MapFrequenciesBy.run([1, 2, 3, 4, 5])
      assert %{0 => 1, 1 => 2, 4 => 2} = EnumancerOldTest.MapFrequenciesBy.run(1..5)
    end

    test "map |> group_by" do
      defmodule EnumancerOldTest.MapGroupBy do
        defenum run(enum) do
          enum |> map(&(&1 * &1)) |> group_by(&rem(&1, 5))
        end
      end

      assert %{0 => [25], 1 => [16, 1], 4 => [9, 4]} =
               EnumancerOldTest.MapGroupBy.run([1, 2, 3, 4, 5])

      assert %{0 => [25], 1 => [16, 1], 4 => [9, 4]} = EnumancerOldTest.MapGroupBy.run(1..5)
    end

    test "map |> sort" do
      defmodule EnumancerOldTest.MapSort do
        defenum run(enum) do
          enum |> map(&(&1 * &1)) |> sort()
        end

        defenum run(enum, :desc) do
          enum |> map(&(&1 * &1)) |> sort(:desc)
        end
      end

      assert [1, 4, 9, 16] = EnumancerOldTest.MapSort.run([3, 1, 4, 2])
      assert [16, 9, 4, 1] = EnumancerOldTest.MapSort.run([3, 1, 4, 2], :desc)
    end

    test "map |> sort_by" do
      defmodule EnumancerOldTest.MapSortBy do
        defenum run(enum) do
          enum |> map(&%{age: &1}) |> sort_by(& &1.age)
        end

        defenum run(enum, :desc) do
          enum |> map(&%{age: &1}) |> sort_by(& &1.age, :desc)
        end
      end

      assert [%{age: 1}, %{age: 2}, %{age: 3}, %{age: 4}] =
               EnumancerOldTest.MapSortBy.run([3, 1, 4, 2])

      assert [%{age: 4}, %{age: 3}, %{age: 2}, %{age: 1}] =
               EnumancerOldTest.MapSortBy.run([3, 1, 4, 2], :desc)
    end

    test "map |> Map.new" do
      defmodule EnumancerOldTest.MapNewMap do
        defenum run(enum) do
          enum |> map(&{to_string(&1), &1}) |> Map.new()
        end
      end

      assert %{"1" => 1, "2" => 2, "3" => 3, "4" => 4} ==
               EnumancerOldTest.MapNewMap.run([3, 1, 4, 2])
    end

    test "map |> MapSet.new" do
      defmodule EnumancerOldTest.MapNewMapSet do
        defenum run(enum) do
          enum |> map(&to_string/1) |> MapSet.new()
        end
      end

      assert MapSet.new(["1", "2", "3"]) == EnumancerOldTest.MapNewMapSet.run([3, 1, 3, 2])
    end

    test "map |> uniq" do
      defmodule EnumancerOldTest.MapUniq do
        defenum run(enum) do
          enum |> map(&(&1 * &1)) |> uniq()
        end
      end

      assert [1, 4, 9] = EnumancerOldTest.MapUniq.run([1, 2, 3, 2, 3])
      assert [1, 4, 9] = [1, 2, 3, 2, 3] |> Stream.map(& &1) |> EnumancerOldTest.MapUniq.run()
    end

    test "uniq |> map" do
      defmodule EnumancerOldTest.UniqMap do
        defenum run(enum) do
          enum |> uniq() |> map(&(&1 * &1))
        end
      end

      assert [1, 4, 9] = EnumancerOldTest.UniqMap.run([1, 2, 3, 2, 3])
      assert [1, 4, 9] = [1, 2, 3, 2, 3] |> Stream.map(& &1) |> EnumancerOldTest.UniqMap.run()
    end

    test "filter |> uniq" do
      defmodule EnumancerOldTest.FilterUniq do
        defenum run(enum) do
          enum |> filter(&(rem(&1, 2) == 1)) |> uniq()
        end
      end

      assert [1, 3] = EnumancerOldTest.FilterUniq.run([1, 2, 3, 2, 3])
      assert [1, 3] = [1, 2, 3, 2, 3] |> Stream.map(& &1) |> EnumancerOldTest.FilterUniq.run()
    end

    test "uniq |> filter" do
      defmodule EnumancerOldTest.UniqFilter do
        defenum run(enum) do
          enum |> uniq() |> filter(&(rem(&1, 2) == 1))
        end
      end

      assert [1, 3] = EnumancerOldTest.UniqFilter.run([1, 2, 3, 2, 3])
      assert [1, 3] = [1, 2, 3, 2, 3] |> Stream.map(& &1) |> EnumancerOldTest.UniqFilter.run()
    end

    test "filter |> dedup" do
      defmodule EnumancerOldTest.FilterDedup do
        defenum run(enum) do
          enum |> filter(&(rem(&1, 2) == 1)) |> dedup()
        end
      end

      assert [1, 3, 1] = EnumancerOldTest.FilterDedup.run([1, 2, 3, 3, 2, 1, 1])

      assert [1, 3, 1] =
               [1, 2, 3, 3, 2, 1, 1] |> Stream.map(& &1) |> EnumancerOldTest.FilterDedup.run()
    end

    test "dedup |> filter" do
      defmodule EnumancerOldTest.DedupFilter do
        defenum run(enum) do
          enum |> dedup() |> filter(&(rem(&1, 2) == 1))
        end
      end

      assert [1, 3, 1] = EnumancerOldTest.DedupFilter.run([1, 2, 3, 3, 2, 1, 1])

      assert [1, 3, 1] =
               [1, 2, 3, 3, 2, 1, 1] |> Stream.map(& &1) |> EnumancerOldTest.DedupFilter.run()
    end

    test "with_index |> filter |> map" do
      defmodule EnumancerOldTest.WithIndexFilterMap do
        defenum run(enum) do
          enum
          |> with_index()
          |> filter(fn {x, _} -> rem(x, 2) == 1 end)
          |> map(fn {x, i} -> {i, x} end)
        end
      end

      assert [{0, 1}, {2, 3}, {4, 5}] = EnumancerOldTest.WithIndexFilterMap.run([1, 2, 3, 4, 5])

      assert [{1, 101}, {3, 103}, {5, 105}] = EnumancerOldTest.WithIndexFilterMap.run(100..105)
    end

    test "drop |> filter" do
      defmodule EnumancerOldTest.DropFilter do
        defenum run(enum) do
          enum
          |> drop(2)
          |> filter(&(rem(&1, 2) == 1))
        end
      end

      assert [3, 5] = EnumancerOldTest.DropFilter.run([1, 2, 3, 4, 5])
      assert [103, 105, 107] = EnumancerOldTest.DropFilter.run(100..108)
    end

    test "filter |> drop" do
      defmodule EnumancerOldTest.FilterDrop do
        defenum run(enum) do
          enum
          |> filter(&(rem(&1, 2) == 1))
          |> drop(2)
        end
      end

      assert [5] = EnumancerOldTest.FilterDrop.run([1, 2, 3, 4, 5])
      assert [105, 107] = EnumancerOldTest.FilterDrop.run(100..108)
    end

    test "scan |> filter" do
      defmodule EnumancerOldTest.ScanFilter do
        defenum run(enum) do
          scan(enum, 0, &(&1 + &2)) |> filter(&(rem(&1, 2) == 1))
        end
      end

      assert [1, 3, 15] = EnumancerOldTest.ScanFilter.run([1, 2, 3, 4, 5])
      assert [1, 3, 15] = EnumancerOldTest.ScanFilter.run(1..5)
    end

    test "map_reduce |> elem(0) |> filter" do
      defmodule EnumancerOldTest.MapReduceNoAccFilter do
        defenum run(enum) do
          enum
          |> map_reduce(0, &{{&1, &2}, &2 + 1})
          |> elem(0)
          |> filter(fn {x, i} -> x + i != 3 end)
        end
      end

      assert [{1, 0}, {3, 2}] = EnumancerOldTest.MapReduceNoAccFilter.run([1, 2, 3])
      assert [{1, 0}, {3, 2}] = EnumancerOldTest.MapReduceNoAccFilter.run(1..3)
    end

    test "filter |> map |> filter |> map" do
      defmodule EnumancerOldTest.FilterMapFilterMap do
        defenum run(enum) do
          enum
          |> filter(&(rem(&1, 2) == 1))
          |> map(&Integer.pow(&1, 2))
          |> filter(&(&1 > 1))
          |> map(&to_string/1)
        end
      end

      assert ["9", "25"] = EnumancerOldTest.FilterMapFilterMap.run([1, 2, 3, 4, 5])
      assert ["9", "25"] = EnumancerOldTest.FilterMapFilterMap.run(1..5)
    end

    test "guards" do
      defmodule EnumancerOldTest.Guards do
        defenum run(enum, fun, joiner) when is_function(fun, 1) and is_binary(joiner) do
          enum
          |> filter(fun)
          |> map(&Integer.pow(&1, 2))
          |> join(joiner)
        end
      end

      assert "1_9_25" = EnumancerOldTest.Guards.run([1, 2, 3, 4, 5], &(rem(&1, 2) == 1), "_")
      assert "1_9_25" = EnumancerOldTest.Guards.run(1..5, &(rem(&1, 2) == 1), "_")

      assert_raise FunctionClauseError, fn ->
        EnumancerOldTest.Guards.run([1, 2, 3, 4, 5], &(rem(&1, 2) == 1), 100)
      end

      assert_raise FunctionClauseError, fn ->
        EnumancerOldTest.Guards.run(1..5, &(rem(&1, 2) == 1), 100)
      end
    end
  end
end
