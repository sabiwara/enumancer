defmodule Enumancer do
  @moduledoc """
  Macros to effortlessly define highly optimized `Enum` pipelines

  ## Overview

  `Enumancer` provides a `defenum/2` macro, which will convert a pipeline of `Enum`
  function calls to an optimized tail-recursive function.

      defmodule BlazingFast do
        import Enumancer

        defenum sum_squares(numbers) do
          numbers
          |> map(& &1 * &1)
          |> sum()
        end
      end

  There is no need to add `Enum.`, `map/2` will be interpreted as `Enum.map/2`
  within `defenum/2`.

  In order to see the actual functions that are being generated, you can just
  replace `defenum/2` by `defenum_explain/2` and the code will be printed in the
  console.

  The `defenum_explain/2` approach can be useful if you don't want to take the risk of
  using `Enumancer` and macros in your production code, but it can inspire the
  implementation of your optimized recursive functions.

  ## Available functions

  Most functions taking an `Enumerable` and returning a list can be used anywhere
  in the pipeline (e.g. `map/2`, `filter/2`, `with_index/2`...).

  On the other hand, functions taking an `Enumerable` and returning some non-list
  accumulator (e.g. `sum/1`, `join/2`, `max/1`...) can only be used at the end of
  the pipeline. There are other cases like `sort/1` or `reduce/1` which cannot work
  without the full list and are also limited to the end of the pipeline.

  Functions that need to stop without reducing the `Enumerable` completely, such as
  `take/2` or `any?/1`, are not available at this point, but might be implemented in the future.

  Also, please note that many functions from the `Enum` module are accepting optional
  callbacks to add an extra map or filter step.
  By design, `Enumancer` does **not** implement these.
  For a very simple reason: the available primitives can be combined at will to
  reproduce them, without any runtime overhead.

  See examples below:

  ### Replacing some "composed" functions

  - Instead of `|> map_join("-", fun)`, just use `|> map(fun) |> join("-")`
  - Instead of `|> map_intersperse(sep, fun)`, just use `|> map(fun) |> intersperse(sep)`
  - Instead of `|> count(&has_valid_foo?/1)`, just use `|> filter(&has_valid_foo?/1) |> count()`
  - Instead of `|> with_index(fn x, i -> foo(x, i) end)`, just use `|> with_index() |> map(fn {x, i} -> foo(x, i) end)`
  - Instead of `|> Map.new(fn x -> {x.k, x.v} end)`, just use `|> map(fn x -> {x.k, x.v} end) |> Map.new()`

  ### Anywhere in the pipeline

  - `Enum.map/2`
  - `Enum.filter/2`
  - `Enum.reduce/2`
  - `Enum.reject/2`
  - `Enum.with_index/1`
  - `Enum.with_index/2` (only accepts integer `offset`)
  - `Enum.uniq/1`
  - `Enum.uniq_by/2`
  - `Enum.dedup/1`
  - `Enum.dedup_by/2`
  - `Enum.scan/2`
  - `Enum.map_reduce/3` + `hd/1` (not plain `Enum.map_reduce/3`!, see explanation below)

  `|> map_reduce(acc, fun)` by itself returns a tuple and cannot be piped any further.

  But `|> map_reduce(acc, fun) |> hd()` can be piped if you only need the mapped list.

  ### Only at the end of the pipeline

  - `Enum.reduce/2`
  - `Enum.reduce/3`
  - `Enum.max/1`
  - `Enum.max/2` (only with a `module` argument)
  - `Enum.min/1`
  - `Enum.min/2` (only with a `module` argument)
  - `Enum.count/1`
  - `Enum.sum/1`
  - `Enum.product/1`
  - `Enum.reverse/1`
  - `Enum.join/1`
  - `Enum.join/2`
  - `Enum.intersperse/2`
  - `Enum.sort/1`
  - `Enum.sort/2`
  - `Enum.sort_by/2`
  - `Enum.sort_by/3`
  - `Enum.map_reduce/3` (without being followed by `|> hd()`)
  - `Enum.frequencies/1`
  - `Enum.frequencies_by/2`
  - `Enum.group_by/2`
  - `Map.new/1`
  - `MapSet.new/1`
  """

  @doc """
  A macro transforming a pipeline of `Enum` transformations to an optimized
  recursive function at compile time.

  See `Enumancer` documentation for available functions.

  ## Examples

      defmodule BlazingFast do
        import Enumancer

        defenum sum_odd_squares(numbers) do
          numbers
          |> filter(&rem(&1, 2) == 1)
          |> map(& &1 * &1)
          |> sum()
        end
      end

  """
  defmacro defenum(head, do: body) do
    do_defenum(head, body, __CALLER__)
  end

  @doc """
  Same as `defenum/2`, but will print the generated code in the console.

  Useful for debug or learning purpose.

  """
  defmacro defenum_explain(head, do: body) do
    ast = do_defenum(head, body, __CALLER__)
    Macro.to_string(ast) |> IO.puts()
    ast
  end

  defp do_defenum(head, body, caller) do
    {fun_name, args, guards} = parse_fun_head(head)
    [{enum_arg_name, _, nil} | rest_args] = args

    enum_fun_name = :"do_#{fun_name}_enum"

    {spec, extra_args_spec} = parse_body(body, enum_arg_name, caller, [], [])
    {extra_args, extra_initial} = Enum.unzip(extra_args_spec)
    spec_last = List.last(spec)
    acc_value = initial_acc(spec_last)

    vars = %{
      rec_fun_name: :"do_#{fun_name}_list",
      head: Macro.unique_var(:head, nil),
      tail: Macro.unique_var(:tail, nil),
      acc: Macro.unique_var(:acc, nil),
      rest_args: rest_args,
      extra_args: extra_args
    }

    main_body =
      quote do
        unquote(vars.acc) =
          case to_list_if_efficient(unquote(hd(args))) do
            list when is_list(list) ->
              unquote(vars.rec_fun_name)(
                list,
                unquote_splicing(rest_args),
                unquote_splicing(extra_initial),
                unquote(acc_value)
              )

            _ ->
              unquote(enum_fun_name)(unquote_splicing(args))
          end

        unquote(wrap_result(spec_last, vars.acc))
      end

    quote do
      unquote(def_main(fun_name, args, guards, main_body))

      defp unquote(vars.rec_fun_name)(
             [],
             unquote_splicing(wildcards(vars.rest_args)),
             unquote_splicing(wildcards(vars.extra_args)),
             acc
           ) do
        acc
      end

      defp unquote(vars.rec_fun_name)(
             [unquote(vars.head) | unquote(vars.tail)],
             unquote_splicing(vars.rest_args),
             unquote_splicing(vars.extra_args),
             unquote(vars.acc)
           ) do
        unquote(define_next_acc(spec, vars))

        unquote(vars.rec_fun_name)(
          unquote(vars.tail),
          unquote_splicing(vars.rest_args),
          unquote_splicing(vars.extra_args),
          unquote(vars.acc)
        )
      end

      defp unquote(enum_fun_name)(enum, unquote_splicing(vars.rest_args)) do
        unquote(to_tuple_if_extras(vars.acc, wildcards(vars.extra_args))) =
          Enum.reduce(
            enum,
            unquote(to_tuple_if_extras(acc_value, extra_initial)),
            fn unquote(vars.head), unquote(composite_acc(vars)) ->
              unquote(define_next_acc(spec, vars))
              unquote(composite_acc(vars))
            end
          )

        unquote(vars.acc)
      end
    end
  end

  defp to_tuple_if_extras(ast, []), do: ast
  defp to_tuple_if_extras(ast, [_ | _] = asts), do: {:{}, [], [ast | asts]}

  defp composite_acc(vars) do
    to_tuple_if_extras(vars.acc, vars.extra_args)
  end

  @dialyzer :no_opaque

  @doc false
  def to_list_if_efficient(enum)
  def to_list_if_efficient(list) when is_list(list), do: list
  def to_list_if_efficient(map) when is_map(map) and not is_struct(map), do: Map.to_list(map)
  def to_list_if_efficient(map_set = %MapSet{}), do: MapSet.to_list(map_set)
  def to_list_if_efficient(enum), do: enum

  defp wildcards(args) do
    for _ <- args, do: Macro.var(:_, nil)
  end

  defp def_main(fun_name, args, _guards = nil, body) do
    quote do
      def unquote(fun_name)(unquote_splicing(args)) do
        unquote(body)
      end
    end
  end

  defp def_main(fun_name, args, {:guards, guards}, body) do
    quote do
      def unquote(fun_name)(unquote_splicing(args)) when unquote(guards) do
        unquote(body)
      end
    end
  end

  defp parse_fun_head({:when, _, [{fun_name, _ctx, args}, guards]}) do
    {fun_name, args, {:guards, guards}}
  end

  defp parse_fun_head({fun_name, _ctx, args}) do
    {fun_name, args, nil}
  end

  defp parse_body({enum_arg_name, _, nil}, enum_arg_name, _caller, acc, extra_args) do
    {acc, extra_args}
  end

  defp parse_body({:|>, _, _} = pipe, enum_arg_name, caller, acc, extra_args) do
    Macro.expand_once(pipe, caller) |> parse_body(enum_arg_name, caller, acc, extra_args)
  end

  defp parse_body(
         {:hd, ctx, [{:map_reduce, _, args}]},
         enum_arg_name,
         caller,
         acc,
         extra_args
       )
       when is_list(args) do
    parse_body({:map_reduce_no_acc, ctx, args}, enum_arg_name, caller, acc, extra_args)
  end

  defp parse_body(
         {fun_name, _, [enum | rest_args] = args},
         enum_arg_name,
         caller,
         acc,
         extra_args
       )
       when is_list(args) do
    case {parse_call(fun_name, rest_args), acc} do
      {{:last_only, _parsed}, [_ | _]} ->
        raise "#{fun_name}/#{length(args)} must be the final call in defenum"

      {{_, parsed}, _} ->
        parse_body(enum, enum_arg_name, caller, [parsed | acc], extra_args)

      {{:extra, parsed, extra_arg}, _} ->
        parse_body(enum, enum_arg_name, caller, [parsed | acc], [extra_arg | extra_args])
    end
  end

  defp parse_call(:map, [fun]) do
    {:anywhere, {:map, fun}}
  end

  defp parse_call(:filter, [fun]) do
    {:anywhere, {:filter, fun}}
  end

  defp parse_call(:reject, [fun]) do
    {:anywhere, {:reject, fun}}
  end

  defp parse_call(:uniq, []) do
    uniq_acc = Macro.unique_var(:uniq_acc, nil)
    {:extra, {:uniq, uniq_acc}, {uniq_acc, Macro.escape(%{})}}
  end

  defp parse_call(:uniq_by, [fun]) do
    uniq_acc = Macro.unique_var(:uniq_acc, nil)
    {:extra, {:uniq_by, uniq_acc, fun}, {uniq_acc, Macro.escape(%{})}}
  end

  defp parse_call(:dedup, []) do
    last = Macro.unique_var(:last, nil)
    {:extra, {:dedup, last}, {last, :__ENUMANCER_RESERVED__}}
  end

  defp parse_call(:dedup_by, [fun]) do
    last = Macro.unique_var(:last, nil)
    {:extra, {:dedup_by, last, fun}, {last, :__ENUMANCER_RESERVED__}}
  end

  defp parse_call(:with_index, []) do
    parse_call(:with_index, [0])
  end

  defp parse_call(:with_index, [offset]) do
    index = Macro.unique_var(:index, nil)
    {:extra, {:with_index, index}, {index, offset}}
  end

  defp parse_call(:drop, [count]) do
    index = Macro.unique_var(:index, nil)

    initial_ast =
      quote do
        case unquote(count) do
          count when is_integer(count) and count >= 0 -> 0
        end
      end

    {:extra, {:drop, index, count}, {index, initial_ast}}
  end

  defp parse_call(:scan, [initial, fun]) do
    scan_acc = Macro.unique_var(:scan_acc, nil)
    {:extra, {:scan, scan_acc, fun}, {scan_acc, initial}}
  end

  defp parse_call(:map_reduce_no_acc, [initial, fun]) do
    mr_acc = Macro.unique_var(:mr_acc, nil)
    {:extra, {:map_reduce_no_acc, mr_acc, fun}, {mr_acc, initial}}
  end

  defp parse_call(:max, []) do
    max_ast =
      quote do
        fn
          x, acc when acc >= x -> acc
          x, acc -> x
        end
      end

    {:last_only, {:reduce, max_ast}}
  end

  defp parse_call(:max, [module_ast = {:__aliases__, _, _}]) do
    max_ast =
      quote do
        fn x, acc ->
          case unquote(module_ast).compare(acc, x) do
            :lt -> x
            _ -> acc
          end
        end
      end

    {:last_only, {:reduce, max_ast}}
  end

  defp parse_call(:min, []) do
    max_ast =
      quote do
        fn
          x, acc when acc <= x -> acc
          x, acc -> x
        end
      end

    {:last_only, {:reduce, max_ast}}
  end

  defp parse_call(:min, [module_ast = {:__aliases__, _, _}]) do
    max_ast =
      quote do
        fn x, acc ->
          case unquote(module_ast).compare(acc, x) do
            :gt -> x
            _ -> acc
          end
        end
      end

    {:last_only, {:reduce, max_ast}}
  end

  defp parse_call(:reduce, [fun]) do
    {:last_only, {:reduce, fun}}
  end

  defp parse_call(:reduce, [acc, fun]) do
    {:last_only, {:reduce, acc, fun}}
  end

  defp parse_call(:reverse, []) do
    {:last_only, {:reverse, []}}
  end

  defp parse_call(:reverse, [acc]) do
    {:last_only, {:reverse, acc}}
  end

  defp parse_call(:each, [fun]) do
    {:last_only, {:each, fun}}
  end

  defp parse_call(:count, []) do
    {:last_only, :count}
  end

  defp parse_call(:sum, []) do
    {:last_only, :sum}
  end

  defp parse_call(:product, []) do
    {:last_only, :product}
  end

  defp parse_call(:join, []) do
    {:last_only, :join}
  end

  defp parse_call(:join, [joiner]) do
    {:last_only, {:join, joiner}}
  end

  defp parse_call(:intersperse, [joiner]) do
    {:last_only, {:intersperse, joiner}}
  end

  defp parse_call(:frequencies, []) do
    {:last_only, :frequencies}
  end

  defp parse_call(:frequencies_by, [fun]) do
    {:last_only, {:frequencies_by, fun}}
  end

  defp parse_call(:group_by, [fun]) do
    {:last_only, {:group_by, fun}}
  end

  defp parse_call(:sort, []) do
    {:last_only, :sort}
  end

  defp parse_call(:sort, [fun]) do
    {:last_only, {:sort, fun}}
  end

  defp parse_call(:sort_by, [mapper]) do
    {:last_only, {:sort_by, mapper, &<=/2}}
  end

  defp parse_call(:sort_by, [mapper, sorter]) do
    {:last_only, {:sort_by, mapper, sorter}}
  end

  defp parse_call({:., _, [{:__aliases__, _, [:Map]}, :new]}, []) do
    {:last_only, Map}
  end

  defp parse_call({:., _, [{:__aliases__, _, [:MapSet]}, :new]}, []) do
    {:last_only, MapSet}
  end

  defp define_next_acc([{:map, fun} | rest], vars) do
    quote do
      unquote(vars.head) = unquote(fun).(unquote(vars.head))
      unquote(define_next_acc(rest, vars))
    end
  end

  defp define_next_acc([{:filter, fun} | rest], vars) do
    quote do
      unquote(composite_acc(vars)) =
        if unquote(fun).(unquote(vars.head)) do
          unquote(define_next_acc(rest, vars))
          unquote(composite_acc(vars))
        else
          unquote(composite_acc(vars))
        end
    end
  end

  defp define_next_acc([{:reject, fun} | rest], vars) do
    quote do
      unquote(composite_acc(vars)) =
        if unquote(fun).(unquote(vars.head)) do
          unquote(composite_acc(vars))
        else
          unquote(define_next_acc(rest, vars))
          unquote(composite_acc(vars))
        end
    end
  end

  defp define_next_acc([{:uniq, uniq_acc} | rest], vars) do
    quote do
      unquote(composite_acc(vars)) =
        case unquote(uniq_acc) do
          %{^unquote(vars.head) => _} ->
            unquote(composite_acc(vars))

          _ ->
            unquote(uniq_acc) = Map.put(unquote(uniq_acc), unquote(vars.head), [])
            unquote(define_next_acc(rest, vars))
            unquote(composite_acc(vars))
        end
    end
  end

  defp define_next_acc([{:uniq_by, uniq_acc, fun} | rest], vars) do
    quote do
      key = unquote(fun).(unquote(vars.head))

      unquote(composite_acc(vars)) =
        case unquote(uniq_acc) do
          %{^key => _} ->
            unquote(composite_acc(vars))

          _ ->
            unquote(uniq_acc) = Map.put(unquote(uniq_acc), key, [])
            unquote(define_next_acc(rest, vars))
            unquote(composite_acc(vars))
        end
    end
  end

  defp define_next_acc([{:dedup, last} | rest], vars) do
    quote do
      unquote(composite_acc(vars)) =
        case unquote(vars.head) do
          ^unquote(last) ->
            unquote(composite_acc(vars))

          _ ->
            unquote(last) = unquote(vars.head)
            unquote(define_next_acc(rest, vars))
            unquote(composite_acc(vars))
        end
    end
  end

  defp define_next_acc([{:dedup_by, last, fun} | rest], vars) do
    quote do
      unquote(composite_acc(vars)) =
        case unquote(fun).(unquote(vars.head)) do
          ^unquote(last) ->
            unquote(composite_acc(vars))

          new_last ->
            unquote(last) = new_last
            unquote(define_next_acc(rest, vars))
            unquote(composite_acc(vars))
        end
    end
  end

  defp define_next_acc([{:with_index, index} | rest], vars) do
    quote do
      unquote(vars.head) = {unquote(vars.head), unquote(index)}
      unquote(index) = unquote(index) + 1
      unquote(define_next_acc(rest, vars))
    end
  end

  defp define_next_acc([{:drop, index, count} | rest], vars) do
    quote do
      unquote(composite_acc(vars)) =
        case unquote(count) do
          ^unquote(index) ->
            unquote(define_next_acc(rest, vars))
            unquote(composite_acc(vars))

          _ ->
            unquote(index) = unquote(index) + 1
            unquote(composite_acc(vars))
        end
    end
  end

  defp define_next_acc([{:scan, scan_acc, fun} | rest], vars) do
    quote do
      unquote(scan_acc) = unquote(fun).(unquote(vars.head), unquote(scan_acc))
      unquote(vars.head) = unquote(scan_acc)

      unquote(define_next_acc(rest, vars))
    end
  end

  defp define_next_acc([{:map_reduce_no_acc, mr_acc, fun} | rest], vars) do
    quote do
      {unquote(vars.head), unquote(mr_acc)} = unquote(fun).(unquote(vars.head), unquote(mr_acc))
      unquote(define_next_acc(rest, vars))
    end
  end

  defp define_next_acc(spec, vars) do
    quote do
      unquote(vars.acc) = unquote(reduce_acc(spec, vars))
    end
  end

  defp reduce_acc([], vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  defp reduce_acc([{:reduce, fun}], vars) do
    quote do
      case unquote(vars.acc) do
        :__ENUMANCER_RESERVED__ ->
          unquote(vars.head)

        acc ->
          unquote(fun).(unquote(vars.head), acc)
      end
    end
  end

  defp reduce_acc([{:reduce, _acc, fun}], vars) do
    quote do
      unquote(fun).(unquote(vars.head), unquote(vars.acc))
    end
  end

  defp reduce_acc([{:reverse, _acc}], vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  defp reduce_acc([{:each, fun}], vars) do
    quote do
      unquote(fun).(unquote(vars.head))
      :ok
    end
  end

  defp reduce_acc([:count], vars) do
    quote do
      unquote(vars.acc) + 1
    end
  end

  defp reduce_acc([:sum], vars) do
    quote do
      unquote(vars.head) + unquote(vars.acc)
    end
  end

  defp reduce_acc([:product], vars) do
    quote do
      unquote(vars.head) * unquote(vars.acc)
    end
  end

  defp reduce_acc([:join], vars) do
    quote do
      [unquote(vars.acc) | to_string(unquote(vars.head))]
    end
  end

  defp reduce_acc([{:join, joiner}], vars) do
    quote do
      [unquote(joiner), to_string(unquote(vars.head)) | unquote(vars.acc)]
    end
  end

  defp reduce_acc([{:intersperse, joiner}], vars) do
    quote do
      [unquote(joiner), unquote(vars.head) | unquote(vars.acc)]
    end
  end

  defp reduce_acc([:frequencies], vars) do
    quote do
      key = unquote(vars.head)

      value =
        case unquote(vars.acc) do
          %{^key => value} -> value
          _ -> 0
        end

      Map.put(unquote(vars.acc), key, value + 1)
    end
  end

  defp reduce_acc([{:frequencies_by, fun}], vars) do
    quote do
      key = unquote(fun).(unquote(vars.head))

      value =
        case unquote(vars.acc) do
          %{^key => value} -> value
          _ -> 0
        end

      Map.put(unquote(vars.acc), key, value + 1)
    end
  end

  defp reduce_acc([{:group_by, fun}], vars) do
    quote do
      key = unquote(fun).(unquote(vars.head))

      list =
        case unquote(vars.acc) do
          %{^key => list} -> list
          _ -> []
        end

      acc = Map.put(unquote(vars.acc), key, [unquote(vars.head) | list])
    end
  end

  defp reduce_acc([:sort], vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  defp reduce_acc([{:sort, _}], vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  defp reduce_acc([{:sort_by, _, _}], vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  defp reduce_acc([Map], vars) do
    quote do
      {key, value} = unquote(vars.head)
      Map.put(unquote(vars.acc), key, value)
    end
  end

  defp reduce_acc([MapSet], vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  defp initial_acc(:count), do: 0
  defp initial_acc(:sum), do: 0
  defp initial_acc(:product), do: 1
  defp initial_acc({:reduce, _reduce_fun}), do: :__ENUMANCER_RESERVED__
  defp initial_acc({:reduce, reduce_acc, _reduce_fun}), do: reduce_acc
  defp initial_acc({:reverse, acc}), do: acc
  defp initial_acc({:each, _fun}), do: :ok
  defp initial_acc(:join), do: ""
  defp initial_acc({:join, _}), do: []
  defp initial_acc(:frequencies), do: Macro.escape(%{})
  defp initial_acc({:frequencies_by, _}), do: Macro.escape(%{})
  defp initial_acc({:group_by, _}), do: Macro.escape(%{})
  defp initial_acc(Map), do: Macro.escape(%{})
  defp initial_acc(MapSet), do: []
  defp initial_acc(_), do: []

  defp wrap_result(:count, acc_ast), do: acc_ast
  defp wrap_result(:sum, acc_ast), do: acc_ast
  defp wrap_result(:product, acc_ast), do: acc_ast

  defp wrap_result({:reduce, _}, acc_ast) do
    quote do
      case unquote(acc_ast) do
        :__ENUMANCER_RESERVED__ -> raise Enum.EmptyError
        acc -> acc
      end
    end
  end

  defp wrap_result({:reduce, _, _}, acc_ast), do: acc_ast
  defp wrap_result({:reverse, _}, acc_ast), do: acc_ast
  defp wrap_result({:each, _}, _), do: :ok
  defp wrap_result(:frequencies, acc_ast), do: acc_ast
  defp wrap_result({:frequencies_by, _}, acc_ast), do: acc_ast
  defp wrap_result({:group_by, _}, acc_ast), do: acc_ast
  defp wrap_result(Map, acc_ast), do: acc_ast

  defp wrap_result(MapSet, acc_ast) do
    quote do
      MapSet.new(unquote(acc_ast))
    end
  end

  defp wrap_result(:sort, acc_ast) do
    quote do
      unquote(acc_ast) |> :lists.sort()
    end
  end

  defp wrap_result({:sort, fun}, acc_ast) do
    quote do
      unquote(acc_ast) |> Enum.sort(unquote(fun))
    end
  end

  defp wrap_result({:sort_by, mapper, sorter}, acc_ast) do
    quote do
      unquote(acc_ast) |> Enum.sort_by(unquote(mapper), unquote(sorter))
    end
  end

  defp wrap_result(:join, acc_ast) do
    quote do
      unquote(acc_ast) |> IO.iodata_to_binary()
    end
  end

  defp wrap_result({:join, _}, acc) do
    quote do
      case unquote(acc) do
        [] -> ""
        [_joiner | rest] -> :lists.reverse(rest) |> IO.iodata_to_binary()
      end
    end
  end

  defp wrap_result({:intersperse, _}, acc_ast) do
    quote do
      case unquote(acc_ast) do
        [] -> []
        [_joiner | rest] -> :lists.reverse(rest)
      end
    end
  end

  defp wrap_result(_, acc_ast) do
    quote do
      :lists.reverse(unquote(acc_ast))
    end
  end
end
