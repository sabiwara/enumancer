keys = Enum.to_list(1..1000)
map1 = Map.new(keys, &{&1, &1})
map2 = Map.put(map1, List.last(keys), :foo)


Benchee.run(%{
  "Enum.all? (Map.get)" => fn -> Enum.all?(keys, fn key ->
     Map.get(map1, key) == Map.get(map2, key) end)
  end,
  "Enum.all? (access)" => fn -> Enum.all?(keys, fn key -> map1[key] == map2[key] end) end,
  "Map.take" => fn ->
    Map.take(map1, keys) == Map.take(map2, keys)
  end,
  "Enum.reduce_while" => fn ->
    Enum.reduce_while(keys, false, fn key, _ ->
      if Map.get(map1, key) == Map.get(map2, key) do
        {:cont, true}
      else
        {:halt, false}
      end
    end)
  end,
}, memory_time: 0.5)
