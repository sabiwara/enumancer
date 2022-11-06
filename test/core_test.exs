defmodule V2.CoreTest do
  use ExUnit.Case, async: true
  doctest V2.Core, import: true

  alias V2, as: E
  alias V2.Core

  describe "prepare_pipeline" do
    defmacrop pp(ast) do
      args = Macro.escape([ast, __CALLER__, []])

      quote do
        Core.prepare_pipeline(unquote_splicing(args))
      end
    end

    test "simple call" do
      assert {[:foo], [%E.Take{value: 1}]} = pp(E.take([:foo], 1))
    end

    test "nested call" do
      assert {[:foo], [%E.Sum{}, %E.Take{value: 1}]} = pp(E.sum(E.take([:foo], 1)))
    end

    test "pipeline" do
      assert {[:foo], [%E.Sum{}, %E.Take{value: 1}]} = pp(E.take([:foo], 1) |> E.sum())
    end
  end
end
