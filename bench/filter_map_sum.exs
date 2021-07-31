list = Enum.to_list(1..100)

defmodule Bench do
  import Enumancer

  def enum(list) do
    list
    |> Enum.filter(&rem(&1, 2) == 1)
    |> Enum.map(& &1 + 1)
    |> Enum.sum()
  end
  def stream(list) do
    list
    |> Stream.filter(&rem(&1, 2) == 1)
    |> Stream.map(& &1 + 1)
    |> Enum.sum()
  end

  def comprehension(list) do
    for x <- list, rem(x, 2) == 1, reduce: 0 do
      acc -> acc + x * x
    end
  end

  defenum enumancer(list) do
    list
    |> filter(&rem(&1, 2) == 1)
    |> map(& &1 + 1)
    |> sum()
  end
end

Benchee.run(%{
  "1. Enum" => fn -> Bench.enum(list) end,
  "2. Stream" => fn ->Bench.stream(list) end,
  "3. for comprehension" => fn ->Bench.comprehension(list) end,
  "4. Enumancer" => fn -> Bench.enumancer(list) end,
})
