list = Enum.to_list(1..100)

defmodule Bench do
  import Enumancer

  def enum(list) do
    Enum.map(list, & &1 + 1) |> Enum.max()
  end

  def stream(list) do
    Stream.map(list, & &1 + 1) |> Enum.max()
  end

  def reduce(list) do
   Enum.reduce(list, &max(&1 + 1, &2))
  end

  defenum enumancer(list) do
    list
    |> map(& &1 + 1)
    |> max()
  end
end

Benchee.run(%{
  "Enum.map/2 |> Enum.max/1" => fn -> Bench.enum(list) end,
  "Stream.map/2 |> Enum.max/1" => fn -> Bench.stream(list) end,
  "Enum.reduce/2" => fn -> Bench.reduce(list) end,
  "Enumancer map/2 |> max/1" => fn -> Bench.enumancer(list) end,
})
