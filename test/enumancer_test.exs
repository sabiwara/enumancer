defmodule EnumancerTest do
  use ExUnit.Case, async: true
  import Enumancer, warn: false
  doctest Enumancer

  describe "defenum" do
    test "map" do
      defmodule EnumancerTest.Map do
        defenum run(enum) do
          map(enum, &to_string/1)
        end
      end

      assert ["1", "2", "3"] = EnumancerTest.Map.run([1, 2, 3])
      assert ["1", "2", "3"] = EnumancerTest.Map.run(1..3)
    end

    test "filter" do
      defmodule EnumancerTest.Filter do
        defenum run(enum) do
          filter(enum, &(rem(&1, 2) == 1))
        end
      end

      assert [1, 3] = EnumancerTest.Filter.run([1, 2, 3])
      assert [1, 3] = EnumancerTest.Filter.run(1..3)
    end

    test "reduce/2" do
      defmodule EnumancerTest.Reduce2 do
        defenum run(enum) do
          reduce(enum, &+/2)
        end
      end

      assert 6 = EnumancerTest.Reduce2.run([1, 2, 3])
      assert 6 = EnumancerTest.Reduce2.run(1..3)

      assert_raise Enum.EmptyError, fn -> EnumancerTest.Reduce2.run([]) end
      assert_raise Enum.EmptyError, fn -> EnumancerTest.Reduce2.run(1..0//1) end
    end

    test "reduce/3" do
      defmodule EnumancerTest.Reduce3 do
        defenum run(enum) do
          reduce(enum, 0, &+/2)
        end
      end

      assert 6 = EnumancerTest.Reduce3.run([1, 2, 3])
      assert 6 = EnumancerTest.Reduce3.run(1..3)
    end

    test "map_reduce/3" do
      defmodule EnumancerTest.MapReduce do
        defenum run(enum) do
          map_reduce(enum, 0, fn x, acc -> {x * 2, x + acc} end)
        end
      end

      assert {[2, 4, 6], 6} = EnumancerTest.MapReduce.run([1, 2, 3])
      assert {[2, 4, 6], 6} = EnumancerTest.MapReduce.run(1..3)
    end

    test "max" do
      defmodule EnumancerTest.Max do
        defenum run(enum) do
          max(enum)
        end
      end

      assert 3 = EnumancerTest.Max.run([1, 3, 1, 2])
      assert 80 = EnumancerTest.Max.run(1..80)
      assert_raise Enum.EmptyError, fn -> EnumancerTest.Max.run([]) end
      assert_raise Enum.EmptyError, fn -> EnumancerTest.Max.run(1..0//1) end
    end

    test "max (module)" do
      defmodule EnumancerTest.MaxModule do
        defenum run(enum) do
          max(enum, Date)
        end
      end

      assert ~D[2022-01-01] =
               EnumancerTest.MaxModule.run([~D[2020-01-03], ~D[2022-01-01], ~D[2021-01-02]])
    end

    test "min" do
      defmodule EnumancerTest.Min do
        defenum run(enum) do
          min(enum)
        end
      end

      assert 1 = EnumancerTest.Min.run([1, 3, 1, 2])
      assert 1 = EnumancerTest.Min.run(1..80)
      assert_raise Enum.EmptyError, fn -> EnumancerTest.Min.run([]) end
      assert_raise Enum.EmptyError, fn -> EnumancerTest.Min.run(1..0//1) end
    end

    test "min (module)" do
      defmodule EnumancerTest.MinModule do
        defenum run(enum) do
          min(enum, Date)
        end
      end

      assert ~D[2020-01-03] =
               EnumancerTest.MinModule.run([~D[2020-01-03], ~D[2022-01-01], ~D[2021-01-02]])
    end

    test "sum" do
      defmodule EnumancerTest.Sum do
        defenum run(enum) do
          sum(enum)
        end
      end

      assert 6 = EnumancerTest.Sum.run([1, 2, 3])
      assert 6 = EnumancerTest.Sum.run(1..3)
    end

    test "product" do
      defmodule EnumancerTest.Product do
        defenum run(enum) do
          product(enum)
        end
      end

      assert 24 = EnumancerTest.Product.run([1, 2, 3, 4])
      assert 24 = EnumancerTest.Product.run(1..4)
    end

    test "join" do
      defmodule EnumancerTest.Join do
        defenum run(enum) do
          join(enum)
        end

        defenum run(enum, joiner) do
          join(enum, joiner)
        end
      end

      assert "123" = EnumancerTest.Join.run([1, 2, 3])
      assert "1-2-3" = EnumancerTest.Join.run([1, 2, 3], "-")
      assert "123" = EnumancerTest.Join.run(1..3)
      assert "1-2-3" = EnumancerTest.Join.run(1..3, "-")
    end

    test "uniq" do
      defmodule EnumancerTest.Uniq do
        defenum run(enum) do
          uniq(enum)
        end
      end

      assert [1, 2, 3] = EnumancerTest.Uniq.run([1, 2, 3, 3, 1])
      assert [1, 2, 3] = [1, 2, 3, 3, 1] |> Stream.map(& &1) |> EnumancerTest.Uniq.run()
    end

    test "uniq_by" do
      defmodule EnumancerTest.UniqBy do
        defenum run(enum) do
          uniq_by(enum, &div(&1, 3))
        end
      end

      assert [1, 3, 6] = EnumancerTest.UniqBy.run([1, 2, 3, 4, 5, 6, 7, 2, 1])
      assert [1, 3, 6] = EnumancerTest.UniqBy.run(1..7)
    end

    test "dedup" do
      defmodule EnumancerTest.Dedup do
        defenum run(enum) do
          dedup(enum)
        end
      end

      assert [1, 2, 3, 1] = EnumancerTest.Dedup.run([1, 2, 3, 3, 1, 1])
      assert [1, 2, 3, 1] = [1, 2, 3, 3, 1, 1] |> Stream.map(& &1) |> EnumancerTest.Dedup.run()
    end

    test "dedup_by" do
      defmodule EnumancerTest.DedupBy do
        defenum run(enum) do
          dedup_by(enum, &div(&1, 3))
        end
      end

      assert [1, 3, 6, 2] = EnumancerTest.DedupBy.run([1, 2, 3, 4, 5, 6, 7, 2, 1])
      assert [1, 3, 6] = EnumancerTest.DedupBy.run(1..7)
    end

    test "with_index" do
      defmodule EnumancerTest.WithIndex do
        defenum run(enum) do
          with_index(enum)
        end

        defenum run(enum, offset) do
          with_index(enum, offset)
        end
      end

      assert [a: 0, b: 1, c: 2] = EnumancerTest.WithIndex.run([:a, :b, :c])
      assert [a: 1, b: 2, c: 3] = EnumancerTest.WithIndex.run([:a, :b, :c], 1)
      assert [{100, 0}, {101, 1}, {102, 2}] = EnumancerTest.WithIndex.run(100..102)
      assert [{100, 1}, {101, 2}, {102, 3}] = EnumancerTest.WithIndex.run(100..102, 1)
    end

    test "drop" do
      defmodule EnumancerTest.Drop do
        defenum run(enum) do
          drop(enum, 1)
        end

        defenum run(enum, count) do
          drop(enum, count)
        end
      end

      assert [:b, :c, :d] = EnumancerTest.Drop.run([:a, :b, :c, :d])
      assert [2, 3, 4] = EnumancerTest.Drop.run(1..4)

      assert [:c, :d] = EnumancerTest.Drop.run([:a, :b, :c, :d], 2)
      assert [999, 1000] = EnumancerTest.Drop.run(1..1000, 998)

      assert_raise CaseClauseError, fn -> EnumancerTest.Drop.run([:a, :b, :c, :d], -1) end
      assert_raise CaseClauseError, fn -> EnumancerTest.Drop.run(1..1000, -1) end
    end

    test "scan" do
      defmodule EnumancerTest.Scan do
        defenum run(enum) do
          scan(enum, 0, &(&1 + &2))
        end
      end

      assert [1, 3, 6, 10, 15] = EnumancerTest.Scan.run([1, 2, 3, 4, 5])
      assert [1, 3, 6, 10, 15] = EnumancerTest.Scan.run(1..5)
    end

    test "map_reduce |> elem(0)" do
      defmodule EnumancerTest.MapReduceNoAcc do
        defenum run(enum) do
          enum |> map_reduce(0, &{{&1, &2}, &2 + 1}) |> elem(0)
        end
      end

      assert [a: 0, b: 1, c: 2] = EnumancerTest.MapReduceNoAcc.run([:a, :b, :c])
      assert [{100, 0}, {101, 1}, {102, 2}] = EnumancerTest.MapReduceNoAcc.run(100..102)
    end

    test "filter |> map" do
      defmodule EnumancerTest.FilterMap do
        defenum run(enum) do
          enum |> filter(&(rem(&1, 2) == 1)) |> map(&to_string/1)
        end
      end

      assert ["1", "3"] = EnumancerTest.FilterMap.run([1, 2, 3])
      assert ["1", "3"] = EnumancerTest.FilterMap.run(1..3)
    end

    test "map |> filter" do
      defmodule EnumancerTest.MapFilter do
        defenum run(enum) do
          enum |> map(&(&1 + 1)) |> filter(&(rem(&1, 2) == 1))
        end
      end

      assert [3, 5] = EnumancerTest.MapFilter.run([1, 2, 3, 4])
      assert [3, 5] = EnumancerTest.MapFilter.run(1..4)
    end

    test "filter |> reduce" do
      defmodule EnumancerTest.FilterReduce do
        defenum run(enum) do
          enum |> filter(&(rem(&1, 2) == 1)) |> reduce(0, &+/2)
        end
      end

      assert 4 = EnumancerTest.FilterReduce.run([1, 2, 3])
      assert 4 = EnumancerTest.FilterReduce.run(1..3)
    end

    test "map |> reverse" do
      defmodule EnumancerTest.MapReverse do
        defenum run(enum) do
          enum |> map(&(&1 * &1)) |> reverse()
        end

        defenum run(enum, list) do
          enum |> map(&(&1 * &1)) |> reverse(list)
        end
      end

      assert [9, 4, 1] = EnumancerTest.MapReverse.run([1, 2, 3])
      assert [9, 4, 1] = EnumancerTest.MapReverse.run(1..3)
      assert [9, 4, 1, 0] = EnumancerTest.MapReverse.run([1, 2, 3], [0])
      assert [9, 4, 1, 0] = EnumancerTest.MapReverse.run(1..3, [0])
    end

    test "map |> each" do
      defmodule EnumancerTest.FilterEach do
        defenum run(enum, fun) do
          enum |> filter(&(rem(&1, 2) == 1)) |> each(fun)
        end
      end

      {:ok, agent} = Agent.start(fn -> [] end)
      add = fn x -> Agent.update(agent, &[x | &1]) end

      assert :ok = EnumancerTest.FilterEach.run([1, 2, 3, 4], add)

      assert [3, 1] = Agent.get(agent, & &1)
    end

    test "reject |> count" do
      defmodule EnumancerTest.RejectCount do
        defenum run(enum) do
          enum |> reject(&(rem(&1, 2) == 1)) |> count()
        end
      end

      assert 2 = EnumancerTest.RejectCount.run([1, 2, 3, 4])
      assert 2 = EnumancerTest.RejectCount.run(1..4)
    end

    test "filter |> max" do
      defmodule EnumancerTest.FilterMax do
        defenum run(enum) do
          enum |> filter(&(rem(&1, 2) == 1)) |> max()
        end
      end

      assert 3 = EnumancerTest.FilterMax.run([1, 2, 3, 4])
      assert 3 = EnumancerTest.FilterMax.run(1..4)
      assert_raise Enum.EmptyError, fn -> EnumancerTest.FilterMax.run([2, 4]) end
      assert_raise Enum.EmptyError, fn -> EnumancerTest.FilterMax.run(2..4//2) end
    end

    test "filter |> sum" do
      defmodule EnumancerTest.FilterSum do
        defenum run(enum) do
          enum |> filter(&(rem(&1, 2) == 1)) |> sum()
        end
      end

      assert 4 = EnumancerTest.FilterSum.run([1, 2, 3])
      assert 4 = EnumancerTest.FilterSum.run(1..3)
    end

    test "filter |> join" do
      defmodule EnumancerTest.FilterJoin do
        defenum run(enum) do
          enum |> filter(&(rem(&1, 2) == 1)) |> join()
        end

        defenum run(enum, joiner) do
          enum |> filter(&(rem(&1, 2) == 1)) |> join(joiner)
        end
      end

      assert "13" = EnumancerTest.FilterJoin.run([1, 2, 3])
      assert "1-3" = EnumancerTest.FilterJoin.run([1, 2, 3], "-")
      assert "13" = EnumancerTest.FilterJoin.run(1..3)
      assert "1-3" = EnumancerTest.FilterJoin.run(1..3, "-")
    end

    test "map |> intersperse" do
      defmodule EnumancerTest.MapIntersperse do
        defenum run(enum) do
          enum |> map(&(&1 * &1)) |> intersperse(0)
        end
      end

      assert [1, 0, 4, 0, 9] = EnumancerTest.MapIntersperse.run([1, 2, 3])
      assert [1, 0, 4, 0, 9] = EnumancerTest.MapIntersperse.run(1..3)
    end

    test "map |> frequencies" do
      defmodule EnumancerTest.MapFrequencies do
        defenum run(enum) do
          enum |> map(&rem(&1, 3)) |> frequencies()
        end
      end

      assert %{0 => 1, 1 => 2, 2 => 2} = EnumancerTest.MapFrequencies.run([1, 2, 3, 4, 5])
      assert %{0 => 1, 1 => 2, 2 => 2} = EnumancerTest.MapFrequencies.run(1..5)
    end

    test "map |> frequencies_by" do
      defmodule EnumancerTest.MapFrequenciesBy do
        defenum run(enum) do
          enum |> map(&(&1 * &1)) |> frequencies_by(&rem(&1, 5))
        end
      end

      assert %{0 => 1, 1 => 2, 4 => 2} = EnumancerTest.MapFrequenciesBy.run([1, 2, 3, 4, 5])
      assert %{0 => 1, 1 => 2, 4 => 2} = EnumancerTest.MapFrequenciesBy.run(1..5)
    end

    test "map |> group_by" do
      defmodule EnumancerTest.MapGroupBy do
        defenum run(enum) do
          enum |> map(&(&1 * &1)) |> group_by(&rem(&1, 5))
        end
      end

      assert %{0 => [25], 1 => [16, 1], 4 => [9, 4]} =
               EnumancerTest.MapGroupBy.run([1, 2, 3, 4, 5])

      assert %{0 => [25], 1 => [16, 1], 4 => [9, 4]} = EnumancerTest.MapGroupBy.run(1..5)
    end

    test "map |> sort" do
      defmodule EnumancerTest.MapSort do
        defenum run(enum) do
          enum |> map(&(&1 * &1)) |> sort()
        end

        defenum run(enum, :desc) do
          enum |> map(&(&1 * &1)) |> sort(:desc)
        end
      end

      assert [1, 4, 9, 16] = EnumancerTest.MapSort.run([3, 1, 4, 2])
      assert [16, 9, 4, 1] = EnumancerTest.MapSort.run([3, 1, 4, 2], :desc)
    end

    test "map |> sort_by" do
      defmodule EnumancerTest.MapSortBy do
        defenum run(enum) do
          enum |> map(&%{age: &1}) |> sort_by(& &1.age)
        end

        defenum run(enum, :desc) do
          enum |> map(&%{age: &1}) |> sort_by(& &1.age, :desc)
        end
      end

      assert [%{age: 1}, %{age: 2}, %{age: 3}, %{age: 4}] =
               EnumancerTest.MapSortBy.run([3, 1, 4, 2])

      assert [%{age: 4}, %{age: 3}, %{age: 2}, %{age: 1}] =
               EnumancerTest.MapSortBy.run([3, 1, 4, 2], :desc)
    end

    test "map |> Map.new" do
      defmodule EnumancerTest.MapNewMap do
        defenum run(enum) do
          enum |> map(&{to_string(&1), &1}) |> Map.new()
        end
      end

      assert %{"1" => 1, "2" => 2, "3" => 3, "4" => 4} ==
               EnumancerTest.MapNewMap.run([3, 1, 4, 2])
    end

    test "map |> MapSet.new" do
      defmodule EnumancerTest.MapNewMapSet do
        defenum run(enum) do
          enum |> map(&to_string/1) |> MapSet.new()
        end
      end

      assert MapSet.new(["1", "2", "3"]) == EnumancerTest.MapNewMapSet.run([3, 1, 3, 2])
    end

    test "map |> uniq" do
      defmodule EnumancerTest.MapUniq do
        defenum run(enum) do
          enum |> map(&(&1 * &1)) |> uniq()
        end
      end

      assert [1, 4, 9] = EnumancerTest.MapUniq.run([1, 2, 3, 2, 3])
      assert [1, 4, 9] = [1, 2, 3, 2, 3] |> Stream.map(& &1) |> EnumancerTest.MapUniq.run()
    end

    test "uniq |> map" do
      defmodule EnumancerTest.UniqMap do
        defenum run(enum) do
          enum |> uniq() |> map(&(&1 * &1))
        end
      end

      assert [1, 4, 9] = EnumancerTest.UniqMap.run([1, 2, 3, 2, 3])
      assert [1, 4, 9] = [1, 2, 3, 2, 3] |> Stream.map(& &1) |> EnumancerTest.UniqMap.run()
    end

    test "filter |> uniq" do
      defmodule EnumancerTest.FilterUniq do
        defenum run(enum) do
          enum |> filter(&(rem(&1, 2) == 1)) |> uniq()
        end
      end

      assert [1, 3] = EnumancerTest.FilterUniq.run([1, 2, 3, 2, 3])
      assert [1, 3] = [1, 2, 3, 2, 3] |> Stream.map(& &1) |> EnumancerTest.FilterUniq.run()
    end

    test "uniq |> filter" do
      defmodule EnumancerTest.UniqFilter do
        defenum run(enum) do
          enum |> uniq() |> filter(&(rem(&1, 2) == 1))
        end
      end

      assert [1, 3] = EnumancerTest.UniqFilter.run([1, 2, 3, 2, 3])
      assert [1, 3] = [1, 2, 3, 2, 3] |> Stream.map(& &1) |> EnumancerTest.UniqFilter.run()
    end

    test "filter |> dedup" do
      defmodule EnumancerTest.FilterDedup do
        defenum run(enum) do
          enum |> filter(&(rem(&1, 2) == 1)) |> dedup()
        end
      end

      assert [1, 3, 1] = EnumancerTest.FilterDedup.run([1, 2, 3, 3, 2, 1, 1])

      assert [1, 3, 1] =
               [1, 2, 3, 3, 2, 1, 1] |> Stream.map(& &1) |> EnumancerTest.FilterDedup.run()
    end

    test "dedup |> filter" do
      defmodule EnumancerTest.DedupFilter do
        defenum run(enum) do
          enum |> dedup() |> filter(&(rem(&1, 2) == 1))
        end
      end

      assert [1, 3, 1] = EnumancerTest.DedupFilter.run([1, 2, 3, 3, 2, 1, 1])

      assert [1, 3, 1] =
               [1, 2, 3, 3, 2, 1, 1] |> Stream.map(& &1) |> EnumancerTest.DedupFilter.run()
    end

    test "with_index |> filter |> map" do
      defmodule EnumancerTest.WithIndexFilterMap do
        defenum run(enum) do
          enum
          |> with_index()
          |> filter(fn {x, _} -> rem(x, 2) == 1 end)
          |> map(fn {x, i} -> {i, x} end)
        end
      end

      assert [{0, 1}, {2, 3}, {4, 5}] = EnumancerTest.WithIndexFilterMap.run([1, 2, 3, 4, 5])

      assert [{1, 101}, {3, 103}, {5, 105}] = EnumancerTest.WithIndexFilterMap.run(100..105)
    end

    test "drop |> filter" do
      defmodule EnumancerTest.DropFilter do
        defenum run(enum) do
          enum
          |> drop(2)
          |> filter(&(rem(&1, 2) == 1))
        end
      end

      assert [3, 5] = EnumancerTest.DropFilter.run([1, 2, 3, 4, 5])
      assert [103, 105, 107] = EnumancerTest.DropFilter.run(100..108)
    end

    test "filter |> drop" do
      defmodule EnumancerTest.FilterDrop do
        defenum run(enum) do
          enum
          |> filter(&(rem(&1, 2) == 1))
          |> drop(2)
        end
      end

      assert [5] = EnumancerTest.FilterDrop.run([1, 2, 3, 4, 5])
      assert [105, 107] = EnumancerTest.FilterDrop.run(100..108)
    end

    test "scan |> filter" do
      defmodule EnumancerTest.ScanFilter do
        defenum run(enum) do
          scan(enum, 0, &(&1 + &2)) |> filter(&(rem(&1, 2) == 1))
        end
      end

      assert [1, 3, 15] = EnumancerTest.ScanFilter.run([1, 2, 3, 4, 5])
      assert [1, 3, 15] = EnumancerTest.ScanFilter.run(1..5)
    end

    test "map_reduce |> elem(0) |> filter" do
      defmodule EnumancerTest.MapReduceNoAccFilter do
        defenum run(enum) do
          enum
          |> map_reduce(0, &{{&1, &2}, &2 + 1})
          |> elem(0)
          |> filter(fn {x, i} -> x + i != 3 end)
        end
      end

      assert [{1, 0}, {3, 2}] = EnumancerTest.MapReduceNoAccFilter.run([1, 2, 3])
      assert [{1, 0}, {3, 2}] = EnumancerTest.MapReduceNoAccFilter.run(1..3)
    end

    test "filter |> map |> filter |> map" do
      defmodule EnumancerTest.FilterMapFilterMap do
        defenum run(enum) do
          enum
          |> filter(&(rem(&1, 2) == 1))
          |> map(&Integer.pow(&1, 2))
          |> filter(&(&1 > 1))
          |> map(&to_string/1)
        end
      end

      assert ["9", "25"] = EnumancerTest.FilterMapFilterMap.run([1, 2, 3, 4, 5])
      assert ["9", "25"] = EnumancerTest.FilterMapFilterMap.run(1..5)
    end

    test "guards" do
      defmodule EnumancerTest.Guards do
        defenum run(enum, fun, joiner) when is_function(fun, 1) and is_binary(joiner) do
          enum
          |> filter(fun)
          |> map(&Integer.pow(&1, 2))
          |> join(joiner)
        end
      end

      assert "1_9_25" = EnumancerTest.Guards.run([1, 2, 3, 4, 5], &(rem(&1, 2) == 1), "_")
      assert "1_9_25" = EnumancerTest.Guards.run(1..5, &(rem(&1, 2) == 1), "_")

      assert_raise FunctionClauseError, fn ->
        EnumancerTest.Guards.run([1, 2, 3, 4, 5], &(rem(&1, 2) == 1), 100)
      end

      assert_raise FunctionClauseError, fn ->
        EnumancerTest.Guards.run(1..5, &(rem(&1, 2) == 1), 100)
      end
    end
  end
end
