list = Enum.to_list(1..100)

defmodule Optimized do
  import Enumancer

  defenum map_sum(list) do
    list
    |> map(& &1 + 1)
    |> sum()
  end
end

Benchee.run(%{
  "Enum.map/2 |> Enum.sum/1" => fn -> Enum.map(list, & &1 + 1) |> Enum.sum() end,
  "Stream.map/2 |> Enum.sum/1" => fn -> Stream.map(list, & &1 + 1) |> Enum.sum() end,
  "Enum.reduce/3" => fn -> Enum.reduce(list, 0, & &1 + &2 + 1) end,
  "Enumancer map/2 |> sum/1" => fn -> Optimized.map_sum(list) end,
})
