range = 1..1000_000

defmodule Optimized do
  import Enumancer

  defenum map_sum(range) do
    range
    |> map(& &1 + 1)
    |> sum()
  end
end

Benchee.run(%{
  "Enum.map/2 |> Enum.sum/1" => fn -> Enum.map(range, & &1 + 1) |> Enum.sum() end,
  "Stream.map/2 |> Enum.sum/1" => fn -> Stream.map(range, & &1 + 1) |> Enum.sum() end,
  "Enum.reduce/3" => fn -> Enum.reduce(range, 0, & &1 + &2 + 1) end,
  "Enumancer map/2 |> sum/1" => fn -> Optimized.map_sum(range) end,
}, memory_time: 1)
