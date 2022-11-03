defmodule V2Test do
  use ExUnit.Case, async: true
  alias V2, as: E
  doctest V2, require: V2
end

defmodule V2.CoreTest do
  use ExUnit.Case, async: true
  doctest V2.Core, import: true
end

defmodule V2.SampleTest do
  use ExUnit.Case, async: true
  doctest V2.Sample
end
