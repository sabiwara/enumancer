defmodule EnumancerTest do
  use ExUnit.Case, async: true
  alias Enumancer, as: E
  doctest Enumancer, require: Enumancer
end

defmodule Enumancer.SampleTest do
  use ExUnit.Case, async: true
  doctest Enumancer.Sample
end
