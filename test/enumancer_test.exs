defmodule EnumancerTest do
  use ExUnit.Case, async: true
  require Enumancer, as: E
  doctest Enumancer
end

defmodule Enumancer.SampleTest do
  use ExUnit.Case, async: true
  doctest Enumancer.Sample
end
