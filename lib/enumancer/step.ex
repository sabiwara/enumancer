defmodule Enumancer.Step do
  import Enumancer.MacroHelpers, only: [to_exprs: 1]

  alias Enumancer.Guards
  alias Enumancer.MacroHelpers

  @type ast :: Macro.t()
  @type vars :: %{head: ast, acc: ast, composite_acc: ast, extra_args: [ast]}
  @type t :: %{
          optional(:collect) => boolean(),
          optional(:halt) => boolean(),
          optional(:extra_args) => list(ast),
          optional(:initial_acc) => (() -> ast),
          optional(:init) => (() -> ast | nil),
          optional(:next_acc) => (vars, ast -> ast),
          optional(:return_acc) => (vars -> ast),
          optional(:wrap_acc) => (ast -> ast)
        }

  @spec initial_acc(t) :: ast
  def initial_acc(step) do
    case step do
      %{initial_acc: fun} -> fun.()
      %{} -> []
    end
  end

  @spec init(t) :: ast | nil
  def init(step) do
    case step do
      %{init: fun} -> fun.()
      %{} -> nil
    end
  end

  @spec next_acc(t, vars, ast) :: ast
  def next_acc(step, vars, continue) do
    case step do
      %{next_acc: fun} -> fun.(vars, continue)
      %{} -> continue
    end
  end

  @spec return_acc(t, vars) :: ast
  def return_acc(step, vars) do
    case step do
      %{return_acc: fun} -> fun.(vars)
      %{} -> quote do: [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  @spec wrap_acc(t, ast) :: ast
  def wrap_acc(step, ast) do
    case step do
      %{wrap_acc: fun} -> fun.(ast)
      %{} -> quote do: :lists.reverse(unquote(ast))
    end
  end

  @spec map(ast) :: t
  def map(fun) do
    %{
      next_acc: fn vars, continue ->
        quote do
          unquote(vars.head) = unquote(fun).(unquote(vars.head))
          unquote_splicing(to_exprs(continue))
        end
      end
    }
  end

  @spec filter(ast) :: t
  def filter(fun) do
    %{
      next_acc: fn vars, continue ->
        quote do
          if unquote(fun).(unquote(vars.head)) do
            (unquote_splicing(to_exprs(continue)))
          else
            unquote(vars.composite_acc)
          end
        end
      end
    }
  end

  @spec sum() :: t
  def sum() do
    %{
      collect: true,
      initial_acc: fn -> 0 end,
      return_acc: fn vars ->
        quote do: unquote(vars.head) + unquote(vars.acc)
      end,
      wrap_acc: fn ast -> ast end
    }
  end

  @spec join(ast) :: t
  def join(_joiner = "") do
    %{
      collect: true,
      return_acc: fn vars ->
        quote do
          string =
            case unquote(vars.head) do
              binary when is_binary(binary) -> binary
              other -> String.Chars.to_string(other)
            end

          [string | unquote(vars.acc)]
        end
      end,
      wrap_acc: fn ast ->
        quote do: :lists.reverse(unquote(ast)) |> IO.iodata_to_binary()
      end
    }
  end

  def join(_joiner = value) do
    joiner = Macro.unique_var(:joiner, nil)

    %{
      collect: true,
      init: fn ->
        quote do: unquote(joiner) = Guards.validate_binary(unquote(value))
      end,
      return_acc: fn vars ->
        quote do
          string =
            case unquote(vars.head) do
              binary when is_binary(binary) -> binary
              other -> String.Chars.to_string(other)
            end

          [unquote(joiner), string | unquote(vars.acc)]
        end
      end,
      wrap_acc: fn ast ->
        quote do
          case unquote(ast) do
            [] -> ""
            [_ | tail] -> :lists.reverse(tail) |> IO.iodata_to_binary()
          end
        end
      end
    }
  end

  @spec uniq() :: t
  def uniq() do
    set = Macro.unique_var(:set, nil)

    %{
      extra_args: [set],
      init: fn ->
        quote do: unquote(set) = %{}
      end,
      next_acc: fn vars, continue ->
        quote do
          case unquote(set) do
            %{^unquote(vars.head) => _} ->
              unquote(vars.composite_acc)

            _ ->
              unquote(set) = Map.put(unquote(set), unquote(vars.head), [])
              unquote_splicing(to_exprs(continue))
          end
        end
      end
    }
  end

  @spec dedup() :: t
  def dedup() do
    previous = Macro.unique_var(:previous, nil)

    %{
      extra_args: [previous],
      init: fn ->
        quote do: unquote(previous) = :__ENUMANCER_RESERVED__
      end,
      next_acc: fn vars, continue ->
        quote do
          case unquote(vars.head) do
            ^unquote(previous) ->
              unquote(vars.composite_acc)

            _ ->
              unquote(previous) = unquote(vars.head)
              unquote_splicing(to_exprs(continue))
          end
        end
      end
    }
  end

  @spec take(ast) :: t
  def take(_amount = value) do
    amount = Macro.unique_var(:amount, nil)

    %{
      halt: true,
      extra_args: [amount],
      init: fn ->
        quote do: unquote(amount) = Guards.validate_positive_integer(unquote(value))
      end,
      next_acc: fn vars, continue ->
        quote do
          case unquote(amount) do
            amount when amount > 0 ->
              unquote(amount) = amount - 1
              unquote_splicing(to_exprs(continue))

            _ ->
              {:__ENUMANCER_HALT__, unquote(vars.composite_acc)}
          end
        end
      end
    }
  end

  @spec drop(ast) :: t
  def drop(_amount = value) do
    amount = Macro.unique_var(:amount, nil)

    %{
      extra_args: [amount],
      init: fn ->
        quote do: unquote(amount) = Guards.validate_positive_integer(unquote(value))
      end,
      next_acc: fn vars, continue ->
        quote do
          case unquote(amount) do
            amount when amount > 0 ->
              unquote(amount) = amount - 1
              unquote(vars.composite_acc)

            _ ->
              (unquote_splicing(to_exprs(continue)))
          end
        end
      end
    }
  end

  @spec at(ast, ast) :: t
  def at(_index = value, default) do
    %{
      collect: true,
      halt: true,
      initial_acc: fn ->
        quote do: Guards.validate_positive_integer(unquote(value))
      end,
      next_acc: fn vars, continue ->
        quote do
          case unquote(vars.acc) do
            index when index > 0 ->
              unquote(vars.acc) = index - 1
              unquote_splicing(to_exprs(continue))

            _ ->
              unquote(vars.acc) = {:ok, unquote(vars.head)}
              {:__ENUMANCER_HALT__, unquote(vars.composite_acc)}
          end
        end
      end,
      return_acc: fn vars -> vars.acc end,
      wrap_acc: fn ast ->
        quote do
          case unquote(ast) do
            {:ok, found} -> found
            index when is_integer(index) -> unquote(default)
          end
        end
      end
    }
  end

  def first(default) do
    %{
      halt: true,
      collect: true,
      initial_acc: fn -> :__ENUMANCER_RESERVED__ end,
      next_acc: fn vars, _continue ->
        quote do
          unquote(vars.acc) = unquote(vars.head)
          {:__ENUMANCER_HALT__, unquote(vars.composite_acc)}
        end
      end,
      wrap_acc: fn ast ->
        quote do
          case unquote(ast) do
            :__ENUMANCER_RESERVED__ -> unquote(default)
            found -> found
          end
        end
      end
    }
  end

  def last(default) do
    %{
      collect: true,
      initial_acc: fn -> :__ENUMANCER_RESERVED__ end,
      next_acc: fn vars, _continue ->
        quote do
          unquote(vars.acc) = unquote(vars.head)
          unquote(vars.composite_acc)
        end
      end,
      wrap_acc: fn ast ->
        quote do
          case unquote(ast) do
            :__ENUMANCER_RESERVED__ -> unquote(default)
            found -> found
          end
        end
      end
    }
  end

  def reverse(tail) do
    %{
      collect: true,
      initial_acc: fn ->
        if is_list(tail) do
          tail
        else
          quote do: Enum.to_list(unquote(tail))
        end
      end,
      wrap_acc: fn ast -> ast end
    }
  end

  def to_list() do
    %{
      collect: true
    }
  end

  def sort(sorter) do
    %{
      collect: true,
      wrap_acc: fn ast ->
        case sorter do
          :asc -> quote do: Enum.sort(unquote(ast))
          _ -> quote do: Enum.sort(unquote(ast), unquote(sorter))
        end
      end
    }
  end

  def flat_map(fun) do
    %{
      next_acc: fn vars, continue ->
        quote do
          # TODO: opti to use ++ if last operation and fun() is a list?
          # TODO: should use reduce_while
          Enum.reduce(unquote(fun).(unquote(vars.head)), unquote(vars.composite_acc), fn
            unquote(vars.head), unquote(vars.composite_acc) ->
              (unquote_splicing(to_exprs(continue)))
          end)
        end
      end
    }
  end

  def from_ast({:map, _, [fun]}), do: map(fun)
  def from_ast({:filter, _, [fun]}), do: filter(fun)
  def from_ast({:sum, _, []}), do: sum()
  def from_ast({:join, _, []}), do: join("")
  def from_ast({:join, _, [joiner]}), do: join(joiner)
  def from_ast({:uniq, _, []}), do: uniq()
  def from_ast({:dedup, _, []}), do: dedup()
  def from_ast({:take, _, [amount]}), do: take(amount)
  def from_ast({:drop, _, [amount]}), do: drop(amount)
  def from_ast({:at, _, [index]}), do: at(index, nil)
  def from_ast({:at, _, [index, default]}), do: at(index, default)
  def from_ast({:first, _, []}), do: first(nil)
  def from_ast({:first, _, [default]}), do: first(default)
  def from_ast({:last, _, []}), do: last(nil)
  def from_ast({:last, _, [default]}), do: last(default)
  def from_ast({:reverse, _, []}), do: reverse([])
  def from_ast({:reverse, _, [tail]}), do: reverse(tail)
  def from_ast({:to_list, _, []}), do: to_list()
  def from_ast({:sort, _, []}), do: sort(:asc)
  def from_ast({:sort, _, [sorter]}), do: sort(sorter)
  def from_ast({:concat, _, []}), do: flat_map(quote do: & &1)
  def from_ast({:flat_map, _, [fun]}), do: flat_map(fun)

  def from_ast(ast) do
    {fun_with_arity, line} = MacroHelpers.fun_arity_and_line(ast)
    raise ArgumentError, "#{line}: Invalid function #{fun_with_arity}"
  end
end
