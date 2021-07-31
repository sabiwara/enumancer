list = Enum.to_list(1..100)

defmodule Bench do
  import Enumancer

  def enum(list) do
    list |> Enum.with_index() |> Enum.map(fn {x, i} -> x + i end)
  end

  def enum_one_pass(list) do
    list |> Enum.with_index(fn x, i -> x + i end)
  end

  defenum enumancer(list) do
    list |> with_index() |> map(fn {x, i} -> x + i end)
  end
end

Benchee.run(%{
  "Enum.with_index |> Enum.map" => fn -> Bench.enum(list) end,
  "Enum.with_index/2" => fn -> Bench.enum_one_pass(list) end,
  "Enumancer" => fn -> Bench.enumancer(list) end,
})
