# Enumancer

Macros to effortlessly define highly optimized `Enum` pipelines.

**Warning**: `Enumancer` is an early proof-of-concept. Expect rough edges.

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
