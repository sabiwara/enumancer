list = Enum.to_list(1..100)

defmodule Optimized do
  import EnumancerOld

  defenum map_add(list) do
    map(list, & &1 + 1)
  end
end

Benchee.run(%{
  "Enum.map/2" => fn -> Enum.map(list, & &1 + 1) end,
  "for" => fn -> for x <- list, do: x + 1 end,
  "EnumancerOld map/2" => fn -> Optimized.map_add(list) end,
})
