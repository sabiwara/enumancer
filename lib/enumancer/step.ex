defmodule Enumancer.Step do
  import Enumancer.MacroHelpers, only: [to_exprs: 1]

  alias Enumancer.Guards
  alias Enumancer.MacroHelpers

  @type ast :: Macro.t()
  @type vars :: %{elem: ast, acc: ast, composite_acc: ast, extra_args: [ast]}
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
      %{} -> quote do: [unquote(vars.elem) | unquote(vars.acc)]
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
          unquote(vars.elem) = unquote(fun).(unquote(vars.elem))
          unquote_splicing(to_exprs(continue))
        end
      end
    }
  end

  @spec with_index(ast) :: t
  def with_index(offset) do
    index = Macro.unique_var(:index, __MODULE__)

    %{
      extra_args: [index],
      init: fn -> quote do: unquote(index) = unquote(offset) end,
      next_acc: fn vars, continue ->
        quote do
          unquote(vars.elem) = {unquote(vars.elem), unquote(index)}
          unquote(index) = unquote(index) + 1
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
          if unquote(fun).(unquote(vars.elem)) do
            (unquote_splicing(to_exprs(continue)))
          else
            unquote(vars.composite_acc)
          end
        end
      end
    }
  end

  @spec reject(ast) :: t
  def reject(fun) do
    %{
      next_acc: fn vars, continue ->
        quote do
          if unquote(fun).(unquote(vars.elem)) do
            unquote(vars.composite_acc)
          else
            (unquote_splicing(to_exprs(continue)))
          end
        end
      end
    }
  end

  @spec split_with(ast) :: t
  def split_with(fun) do
    rejected = Macro.unique_var(:rejected, __MODULE__)

    %{
      collect: true,
      extra_args: [rejected],
      init: fn -> quote do: unquote(rejected) = [] end,
      next_acc: fn vars, continue ->
        quote do
          if unquote(fun).(unquote(vars.elem)) do
            (unquote_splicing(to_exprs(continue)))
          else
            unquote(rejected) = [unquote(vars.elem) | unquote(rejected)]
            unquote(vars.composite_acc)
          end
        end
      end,
      wrap_acc: fn ast ->
        quote do: {:lists.reverse(unquote(ast)), :lists.reverse(unquote(rejected))}
      end
    }
  end

  @spec take(ast) :: t
  def take(_amount = value) do
    amount = Macro.unique_var(:amount, __MODULE__)

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
    amount = Macro.unique_var(:amount, __MODULE__)

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

  @spec split(ast) :: t
  def split(_amount = value) do
    amount = Macro.unique_var(:amount, __MODULE__)
    dropped = Macro.unique_var(:dropped, __MODULE__)

    %{
      collect: true,
      extra_args: [amount, dropped],
      init: fn ->
        quote do
          unquote(amount) = Guards.validate_positive_integer(unquote(value))
          unquote(dropped) = []
        end
      end,
      next_acc: fn vars, continue ->
        quote do
          case unquote(amount) do
            amount when amount > 0 ->
              unquote(amount) = amount - 1
              (unquote_splicing(to_exprs(continue)))

            _ ->
              unquote(dropped) = [unquote(vars.elem) | unquote(dropped)]
              unquote(vars.composite_acc)
          end
        end
      end,
      wrap_acc: fn ast ->
        quote do: {:lists.reverse(unquote(ast)), :lists.reverse(unquote(dropped))}
      end
    }
  end

  @spec take_while(ast) :: t
  def take_while(fun) do
    %{
      halt: true,
      next_acc: fn vars, continue ->
        quote do
          if unquote(fun).(unquote(vars.elem)) do
            (unquote_splicing(to_exprs(continue)))
          else
            {:__ENUMANCER_HALT__, unquote(vars.composite_acc)}
          end
        end
      end
    }
  end

  @spec drop_while(ast) :: t
  def drop_while(fun) do
    %{
      next_acc: fn vars, continue ->
        quote do
          if unquote(fun).(unquote(vars.elem)) do
            unquote(vars.composite_acc)
          else
            (unquote_splicing(to_exprs(continue)))
          end
        end
      end
    }
  end

  @spec split_while(ast) :: t
  def split_while(fun) do
    dropped = Macro.unique_var(:dropped, __MODULE__)

    %{
      collect: true,
      extra_args: [dropped],
      init: fn ->
        quote do
          unquote(dropped) = []
        end
      end,
      next_acc: fn vars, continue ->
        quote do
          if unquote(fun).(unquote(vars.elem)) do
            (unquote_splicing(to_exprs(continue)))
          else
            unquote(dropped) = [unquote(vars.elem) | unquote(dropped)]
            unquote(vars.composite_acc)
          end
        end
      end,
      wrap_acc: fn ast ->
        quote do: {:lists.reverse(unquote(ast)), :lists.reverse(unquote(dropped))}
      end
    }
  end

  @spec uniq_by(ast) :: t
  def uniq_by(fun) do
    set = Macro.unique_var(:set, __MODULE__)

    %{
      extra_args: [set],
      init: fn ->
        quote do: unquote(set) = %{}
      end,
      next_acc: fn vars, continue ->
        quote do
          key = unquote(MacroHelpers.maybe_apply_fun(fun, vars.elem))

          case unquote(set) do
            %{^key => _} ->
              unquote(vars.composite_acc)

            _ ->
              unquote(set) = Map.put(unquote(set), key, [])
              unquote_splicing(to_exprs(continue))
          end
        end
      end
    }
  end

  @spec dedup_by(ast) :: t
  def dedup_by(fun) do
    previous = Macro.unique_var(:previous, __MODULE__)

    %{
      extra_args: [previous],
      init: fn ->
        quote do: unquote(previous) = :__ENUMANCER_RESERVED__
      end,
      next_acc: fn vars, continue ->
        quote do
          case unquote(MacroHelpers.maybe_apply_fun(fun, vars.elem)) do
            ^unquote(previous) ->
              unquote(vars.composite_acc)

            current ->
              unquote(previous) = current
              unquote_splicing(to_exprs(continue))
          end
        end
      end
    }
  end

  @spec reduce(ast) :: t
  def reduce(fun) do
    %{
      collect: true,
      initial_acc: fn -> :__ENUMANCER_RESERVED__ end,
      return_acc: fn vars ->
        quote do
          case unquote(vars.acc) do
            :__ENUMANCER_RESERVED__ -> unquote(vars.elem)
            acc -> unquote(fun).(unquote(vars.elem), acc)
          end
        end
      end,
      wrap_acc: fn ast ->
        quote do
          case unquote(ast) do
            :__ENUMANCER_RESERVED__ -> raise Enum.EmptyError
            acc -> acc
          end
        end
      end
    }
  end

  @spec reduce(ast, ast) :: t
  def reduce(initial, fun) do
    %{
      collect: true,
      initial_acc: fn -> initial end,
      return_acc: fn vars ->
        quote do: unquote(fun).(unquote(vars.elem), unquote(vars.acc))
      end,
      wrap_acc: fn ast -> ast end
    }
  end

  @spec scan(ast, ast) :: t
  def scan(initial, fun) do
    last_acc = Macro.unique_var(:initial, __MODULE__)

    %{
      init: fn -> quote do: unquote(last_acc) = unquote(initial) end,
      extra_args: [last_acc],
      next_acc: fn vars, continue ->
        quote do
          unquote(last_acc) =
            unquote(vars.elem) = unquote(fun).(unquote(vars.elem), unquote(last_acc))

          unquote_splicing(to_exprs(continue))
        end
      end
    }
  end

  @spec each(ast) :: t
  def each(fun) do
    %{
      collect: true,
      initial_acc: fn -> :ok end,
      next_acc: fn vars, continue ->
        quote do
          unquote(fun).(unquote(vars.elem))
          unquote_splicing(to_exprs(continue))
        end
      end,
      return_acc: fn vars -> vars.acc end,
      wrap_acc: fn ast -> ast end
    }
  end

  @spec count() :: t
  def count() do
    %{
      collect: true,
      initial_acc: fn -> 0 end,
      return_acc: fn vars ->
        quote do: unquote(vars.acc) + 1
      end,
      wrap_acc: fn ast -> ast end
    }
  end

  @spec sum() :: t
  def sum() do
    %{
      collect: true,
      initial_acc: fn -> 0 end,
      return_acc: fn vars ->
        quote do: unquote(vars.elem) + unquote(vars.acc)
      end,
      wrap_acc: fn ast -> ast end
    }
  end

  @spec product() :: t
  def product() do
    %{
      collect: true,
      initial_acc: fn -> 1 end,
      return_acc: fn vars ->
        quote do: unquote(vars.elem) * unquote(vars.acc)
      end,
      wrap_acc: fn ast -> ast end
    }
  end

  @spec mean() :: t
  def mean() do
    count = Macro.unique_var(:count, __MODULE__)

    %{
      collect: true,
      extra_args: [count],
      initial_acc: fn -> 0 end,
      init: fn -> quote do: unquote(count) = 0 end,
      next_acc: fn _vars, continue ->
        quote do
          unquote(count) = unquote(count) + 1
          unquote_splicing(to_exprs(continue))
        end
      end,
      return_acc: fn vars ->
        quote do
          unquote(vars.elem) + unquote(vars.acc)
        end
      end,
      wrap_acc: fn ast -> quote do: unquote(ast) / unquote(count) end
    }
  end

  @spec max() :: t
  def max() do
    do_min_max(fn vars ->
      quote do
        acc when acc >= unquote(vars.elem) -> acc
        _ -> unquote(vars.elem)
      end
    end)
  end

  @spec min() :: t
  def min() do
    do_min_max(fn vars ->
      quote do
        acc when acc <= unquote(vars.elem) -> acc
        _ -> unquote(vars.elem)
      end
    end)
  end

  defp do_min_max(clauses_fun) do
    %{
      collect: true,
      initial_acc: fn -> :__ENUMANCER_RESERVED__ end,
      return_acc: fn vars ->
        clauses =
          quote do
            :__ENUMANCER_RESERVED__ -> unquote(vars.elem)
          end ++ clauses_fun.(vars)

        quote do
          case unquote(vars.acc) do
            unquote(clauses)
          end
        end
      end,
      wrap_acc: fn ast ->
        quote do
          case unquote(ast) do
            :__ENUMANCER_RESERVED__ -> raise Enum.EmptyError
            acc -> acc
          end
        end
      end
    }
  end

  @spec frequencies_by(ast) :: t
  def frequencies_by(fun) do
    %{
      collect: true,
      initial_acc: fn -> quote do: %{} end,
      return_acc: fn vars ->
        quote do
          unquote_splicing(maybe_apply_and_reassign(vars.elem, fun))

          case unquote(vars.acc) do
            acc = %{^unquote(vars.elem) => count} -> %{acc | unquote(vars.elem) => count + 1}
            acc -> Map.put(acc, unquote(vars.elem), 1)
          end
        end
      end,
      wrap_acc: fn ast -> ast end
    }
  end

  @spec group_by(ast, ast) :: t
  def group_by(key_fun, value_fun) do
    %{
      collect: true,
      initial_acc: fn -> quote do: %{} end,
      return_acc: fn vars ->
        quote do
          key = unquote(key_fun).(unquote(vars.elem))
          unquote_splicing(maybe_apply_and_reassign(vars.elem, value_fun))

          case unquote(vars.acc) do
            acc = %{^key => list} -> %{acc | key => [unquote(vars.elem) | list]}
            acc -> Map.put(acc, key, [unquote(vars.elem)])
          end
        end
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
            case unquote(vars.elem) do
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
    joiner = Macro.unique_var(:joiner, __MODULE__)

    %{
      collect: true,
      init: fn ->
        quote do: unquote(joiner) = Guards.validate_binary(unquote(value))
      end,
      return_acc: fn vars ->
        quote do
          string =
            case unquote(vars.elem) do
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

  @spec empty?() :: t
  def empty?() do
    %{
      collect: true,
      halt: true,
      initial_acc: fn -> true end,
      next_acc: fn vars, _continue ->
        quote do
          unquote(vars.acc) = false
          {:__ENUMANCER_HALT__, unquote(vars.composite_acc)}
        end
      end,
      wrap_acc: fn ast -> ast end
    }
  end

  @spec any?() :: t
  def any?() do
    %{
      collect: true,
      halt: true,
      initial_acc: fn -> false end,
      next_acc: fn vars, _continue ->
        quote do
          if unquote(vars.elem) do
            unquote(vars.acc) = true
            {:__ENUMANCER_HALT__, unquote(vars.composite_acc)}
          else
            unquote(vars.composite_acc)
          end
        end
      end,
      wrap_acc: fn ast -> ast end
    }
  end

  @spec all?() :: t
  def all?() do
    %{
      collect: true,
      halt: true,
      initial_acc: fn -> true end,
      next_acc: fn vars, _continue ->
        quote do
          if unquote(vars.elem) do
            unquote(vars.composite_acc)
          else
            unquote(vars.acc) = false
            {:__ENUMANCER_HALT__, unquote(vars.composite_acc)}
          end
        end
      end,
      wrap_acc: fn ast -> ast end
    }
  end

  @spec find(ast, ast) :: t
  def find(default, fun) do
    %{
      collect: true,
      halt: true,
      initial_acc: fn -> :__ENUMANCER_RESERVED__ end,
      next_acc: fn vars, _continue ->
        quote do
          if unquote(fun).(unquote(vars.elem)) do
            unquote(vars.acc) = unquote(vars.elem)
            {:__ENUMANCER_HALT__, unquote(vars.composite_acc)}
          else
            unquote(vars.composite_acc)
          end
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

  @spec find_value(ast, ast) :: t
  def find_value(default, fun) do
    %{
      collect: true,
      halt: true,
      initial_acc: fn -> :__ENUMANCER_RESERVED__ end,
      next_acc: fn vars, _continue ->
        quote do
          if value = unquote(fun).(unquote(vars.elem)) do
            unquote(vars.acc) = value
            {:__ENUMANCER_HALT__, unquote(vars.composite_acc)}
          else
            unquote(vars.composite_acc)
          end
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

  @spec find_index(ast) :: t
  def find_index(fun) do
    %{
      collect: true,
      halt: true,
      initial_acc: fn -> 0 end,
      next_acc: fn vars, _continue ->
        quote do
          if unquote(fun).(unquote(vars.elem)) do
            unquote(vars.acc) = {:ok, unquote(vars.acc)}
            {:__ENUMANCER_HALT__, unquote(vars.composite_acc)}
          else
            unquote(vars.acc) = unquote(vars.acc) + 1
            unquote(vars.composite_acc)
          end
        end
      end,
      wrap_acc: fn ast ->
        quote do
          case unquote(ast) do
            {:ok, index} -> index
            _ -> nil
          end
        end
      end
    }
  end

  @spec at(ast, ast) :: t
  def at(index, default) do
    do_fetch(index, fn ast ->
      quote do
        case unquote(ast) do
          {:ok, found} -> found
          index when is_integer(index) -> unquote(default)
        end
      end
    end)
  end

  @spec fetch(ast) :: t
  def fetch(index) do
    do_fetch(index, fn ast ->
      quote do
        case unquote(ast) do
          index when is_integer(index) -> :error
          ok_tuple -> ok_tuple
        end
      end
    end)
  end

  @spec fetch!(ast) :: t
  def fetch!(index) do
    do_fetch(index, fn ast ->
      quote do
        case unquote(ast) do
          {:ok, found} -> found
          index when is_integer(index) -> raise Enum.OutOfBoundsError
        end
      end
    end)
  end

  defp do_fetch(_index = value, wrap_app) do
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
              unquote(vars.acc) = {:ok, unquote(vars.elem)}
              {:__ENUMANCER_HALT__, unquote(vars.composite_acc)}
          end
        end
      end,
      return_acc: fn vars -> vars.acc end,
      wrap_acc: wrap_app
    }
  end

  def first(default) do
    %{
      halt: true,
      collect: true,
      initial_acc: fn -> :__ENUMANCER_RESERVED__ end,
      next_acc: fn vars, _continue ->
        quote do
          unquote(vars.acc) = unquote(vars.elem)
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
          unquote(vars.acc) = unquote(vars.elem)
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
        args =
          case sorter do
            :asc -> [ast]
            _ -> [ast, sorter]
          end

        quote do: Enum.sort(unquote_splicing(args))
      end
    }
  end

  def sort_by(fun, sorter) do
    %{
      collect: true,
      wrap_acc: fn ast ->
        args =
          case sorter do
            :asc -> [ast, fun]
            _ -> [ast, fun, sorter]
          end

        quote do: Enum.sort_by(unquote_splicing(args))
      end
    }
  end

  def shuffle() do
    %{
      collect: true,
      wrap_acc: fn ast ->
        quote do: Enum.shuffle(unquote(ast))
      end
    }
  end

  def flat_map(fun) do
    %{
      next_acc: fn vars, continue ->
        quote do
          unquote_splicing(maybe_apply_and_reassign(vars.elem, fun))
          # TODO: opti to use ++ if last operation and fun() is a list?
          # TODO: should use reduce_while
          Enum.reduce(unquote(vars.elem), unquote(vars.composite_acc), fn
            unquote(vars.elem), unquote(vars.composite_acc) ->
              (unquote_splicing(to_exprs(continue)))
          end)
        end
      end
    }
  end

  @identity quote(do: & &1)

  def from_ast({:map, _, [fun]}), do: map(fun)
  def from_ast({:with_index, _, []}), do: with_index(0)
  def from_ast({:with_index, _, [fun]}), do: with_index(fun)
  def from_ast({:filter, _, [fun]}), do: filter(fun)
  def from_ast({:reject, _, [fun]}), do: reject(fun)
  def from_ast({:split_with, _, [fun]}), do: split_with(fun)
  def from_ast({:take, _, [amount]}), do: take(amount)
  def from_ast({:drop, _, [amount]}), do: drop(amount)
  def from_ast({:split, _, [amount]}), do: split(amount)
  def from_ast({:take_while, _, [fun]}), do: take_while(fun)
  def from_ast({:drop_while, _, [fun]}), do: drop_while(fun)
  def from_ast({:split_while, _, [fun]}), do: split_while(fun)
  def from_ast({:uniq, _, []}), do: uniq_by(@identity)
  def from_ast({:uniq_by, _, [fun]}), do: uniq_by(fun)
  def from_ast({:dedup, _, []}), do: dedup_by(@identity)
  def from_ast({:dedup_by, _, [fun]}), do: dedup_by(fun)
  def from_ast({:count, _, []}), do: count()
  def from_ast({:reduce, _, [fun]}), do: reduce(fun)
  def from_ast({:reduce, _, [acc, fun]}), do: reduce(acc, fun)
  def from_ast({:scan, _, [acc, fun]}), do: scan(acc, fun)
  def from_ast({:each, _, [fun]}), do: each(fun)
  def from_ast({:sum, _, []}), do: sum()
  def from_ast({:product, _, []}), do: product()
  def from_ast({:mean, _, []}), do: mean()
  def from_ast({:max, _, []}), do: max()
  def from_ast({:min, _, []}), do: min()
  def from_ast({:frequencies, _, []}), do: frequencies_by(@identity)
  def from_ast({:frequencies_by, _, [fun]}), do: frequencies_by(fun)
  def from_ast({:group_by, _, [key_fun]}), do: group_by(key_fun, @identity)
  def from_ast({:group_by, _, [key_fun, value_fun]}), do: group_by(key_fun, value_fun)
  def from_ast({:join, _, []}), do: join("")
  def from_ast({:join, _, [joiner]}), do: join(joiner)
  def from_ast({:empty?, _, []}), do: empty?()
  def from_ast({:any?, _, []}), do: any?()
  def from_ast({:all?, _, []}), do: all?()
  def from_ast({:find, _, [fun]}), do: find(nil, fun)
  def from_ast({:find, _, [default, fun]}), do: find(default, fun)
  def from_ast({:find_value, _, [fun]}), do: find_value(nil, fun)
  def from_ast({:find_value, _, [default, fun]}), do: find_value(default, fun)
  def from_ast({:find_index, _, [fun]}), do: find_index(fun)
  def from_ast({:at, _, [index]}), do: at(index, nil)
  def from_ast({:fetch, _, [index]}), do: fetch(index)
  def from_ast({:fetch!, _, [index]}), do: fetch!(index)
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
  def from_ast({:sort_by, _, [fun]}), do: sort_by(fun, :asc)
  def from_ast({:sort_by, _, [fun, sorter]}), do: sort_by(fun, sorter)
  def from_ast({:shuffle, _, []}), do: shuffle()
  def from_ast({:concat, _, []}), do: flat_map(@identity)
  def from_ast({:flat_map, _, [fun]}), do: flat_map(fun)

  def from_ast(ast) do
    {fun_with_arity, line} = MacroHelpers.fun_arity_and_line(ast)
    raise ArgumentError, "#{line}: Invalid function #{fun_with_arity}"
  end

  defp maybe_apply_and_reassign(var, fun) do
    case MacroHelpers.maybe_apply_fun(fun, var) do
      ^var -> []
      applied -> [quote(do: unquote(var) = unquote(applied))]
    end
  end
end
