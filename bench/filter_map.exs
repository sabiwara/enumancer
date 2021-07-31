list = Enum.to_list(1..100)

defmodule Optimized do
  import Enumancer

  defenum filter_odds_map_add(list) do
    list
    |> filter(& rem(&1, 2) == 1)
    |> map(& &1 + 1)
  end
end

Benchee.run(%{
  "Enum.filter/2 |> Enum.map/2" => fn -> Enum.filter(list, & rem(&1, 2) == 1) |> Enum.map(& &1 + 1) end,
  "Stream.filter/2 |> Enum.map/2" => fn -> Stream.filter(list, & rem(&1, 2) == 1) |> Enum.map(& &1 + 1)  end,
  "for" => fn -> for x <- list, rem(x, 2) == 1, do: x + 1 end,
  "Enumancer filter/2 |> map/2" => fn -> Optimized.filter_odds_map_add(list) end,
})
