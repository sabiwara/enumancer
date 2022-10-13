# Enumancer

[![Hex Version](https://img.shields.io/hexpm/v/enumancer.svg)](https://hex.pm/packages/enumancer)
[![docs](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/enumancer/)
[![CI](https://github.com/sabiwara/enumancer/workflows/CI/badge.svg)](https://github.com/sabiwara/enumancer/actions?query=workflow%3ACI)

Elixir macros to effortlessly define highly optimized `Enum` pipelines.

**Warning**: `Enumancer` is still an early proof-of-concept.

## Overview

`Enumancer` provides a `defenum/2` macro, which will convert a pipeline of
`Enum` function calls to an highly optimized tail-recursive function.

```elixir
defmodule BlazingFast do
  import Enumancer

  defenum sum_squares(numbers) do
    numbers
    |> map(& &1 * &1)
    |> sum()
  end
end

1..10_000_000 |> BlazingFast.sum_squares()  # very fast
1..10_000_000 |> Enum.map(& &1 * &1) |> Enum.sum()  # super slow
1..10_000_000 |> Stream.map(& &1 * &1) |> Enum.sum()  # super slow
```

There is no need to add `Enum.`, `map/2` will be interpreted as `Enum.map/2`
within `defenum/2`.

In order to see the actual functions that are being generated, you can just
replace `defenum/2` by `defenum_explain/2` and the code will be printed in the
console.

The `defenum_explain/2` approach can be useful if you don't want to take the
risk of using `Enumancer` and macros in your production code, but it can inspire
the implementation of your optimized recursive functions.

## Motivation

Premature optimization is the root of all evil. For most typical use cases, your
`Enum` code performance is going to be good enough, with the bottleneck being
I/O anyway (typically your database).

For cases where you actually need the performance, however, `Enumancer` aims to
offer an appealing option which will be

- faster and using less memory than `Enum` pipelines, which are building
  wasteful intermediate lists
- faster than `Stream` pipelines which come with a runtime overhead (`Enumancer`
  is compile time)
- more flexible than `for` comprehensions (and also, faster)
- easier to write than handcrafted recursive functions, since it looks like an
  idiomatic Elixir pipeline

See the _Case study_ section for more detailed explanation.

## Performance

`Enumancer`'s performance basically relies on four pillars:

1. memory usage and algorithm: no intermediate lists, just the needed
   accumulator
2. specific tail-recursive functions: these are very fast!
3. compile-time: no runtime overhead needed
4. inlined anonymous functions: anonymous function application have a noticeable
   overhead. When directly passing an anonymous function definition (e.g.
   `fn x -> x + 1 end` or `&foo(&1, :bar)`) inside a `defenum` pipeline, without
   assigning it to a variable, they will be inlined by the compiler in the
   generated function definition, removing this overhead

Some benchmarks are available inside the `bench` folder.

## Installation

`Enumancer` can be installed by adding `enumancer` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [
    {:enumancer, "~> 0.0.1"}
  ]
end
```

Or, if you are using Elixir 1.12, you can just try it out from `iex` or an
`.exs` script:

```elixir
iex> Mix.install([:enumancer])
:ok
```

The documentation can be found at
[https://hexdocs.pm/enumancer](https://hexdocs.pm/enumancer).

## Case study

Let's assume we want to sum the square of all odd numbers within a list. We
could typically write:

```elixir
def sum_odd_squares_1(list) do
  list
  |> Enum.filter(&rem(&1, 2) == 1)
  |> Enum.map(& &1 * &1)
  |> Enum.sum()
end
```

For typical use cases that are not performance sensistive, this will work just
fine. But if this is performance critical or needs to work with big lists, this
will be highly wasteful: `Enum.filter/2` and `Enum.map/2` will both generate
intermediate lists while we only need to keep an integer as accumulator.

A possibile alternative could be to rewrite this using streams to avoid the
intermediate structures:

```elixir
def sum_odd_squares_2(list) do
  list
  |> Stream.filter(&rem(&1, 2) == 1)
  |> Stream.map(& &1 * &1)
  |> Enum.sum()
end
```

However, streams come with their own overhead and this might not be that fast in
practice: don't be surprised if your code suddenly got 3 times slower!

The better alternative in this case would probably be to use a comprehension:

```elixir
def sum_odd_squares_3(list) do
  for x <- list, rem(x, 2) == 1, reduce: 0 do
    acc -> acc + x * x
  end
end
```

But comprehensions can be harder to compose and offer less possibilities than
the `Enum` module. What if you wanted to use `Enum.join/2` instead of
`Enum.sum/1`?

Comprehensions with the `:reduce` option can be also less declarative than the
`Enum` versions: instead of the term `sum`, you have to explicitly manage an
accumulator initiallized to `0`.

Finally, the fastest option would be to write a dedicated recursive function
optimized for this use case:

```elixir
def sum_odd_squares_4(list) do
  do_sum_odd_squares_list(list, 0)
end

defp do_sum_odd_squares_list([], acc), do: acc
defp do_sum_odd_squares_list([head | tail], acc) do
  acc =
    if rem(head, 2) == 1 do
      acc = acc + head * head
    else
      acc
    end

  do_sum_odd_squares_list(tail, acc)
end
```

While this is the best option performance-wise, you would need to sacrifice
readability and maintainability, making the tradeoff less attractive.

With the `defenum/2` macro, you would just write

```elixir
defenum sum_odd_squares_5(list) do
  list
  |> filter(&rem(&1, 2) == 1)
  |> map(& &1 * &1)
  |> sum()
end
```

and this would basically transpile to the previous recursive version.

You get to keep both the declarative and powerful syntax of the 1st version
using `Enum`, and the performance of the most efficient implementation (4th
version) using recursion.

## Copyright and License

Enumancer is licensed under the [MIT License](LICENSE.md).
