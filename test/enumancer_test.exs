defmodule EnumancerTest do
  use ExUnit.Case
  doctest Enumancer

  test "greets the world" do
    assert Enumancer.hello() == :world
  end
end
