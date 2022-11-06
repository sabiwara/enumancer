defmodule V2.Core do
  alias V2.Step

  def inspect_ast(ast) do
    ast |> Macro.to_string() |> IO.puts()
    ast
  end

  defmacro def_enum({fun, _, [enum | args]}) do
    quote do
      defmacro unquote(fun)(unquote_splicing([enum | args])) do
        meta = Macro.Env.location(__CALLER__)
        pipeline(unquote(enum), __CALLER__, [{unquote(fun), meta, unquote(args)}])
      end
    end
  end

  def pipeline(ast, env, acc) do
    ast
    |> prepare_pipeline(env, acc)
    |> transpile_pipeline()
  end

  def prepare_pipeline(ast, env, acc) do
    {first, asts} = extract_pipeline_asts(ast, env, acc)
    steps = asts_to_steps(asts, [])
    {first, steps}
  end

  defp extract_pipeline_asts(ast, env, acc) do
    case split_call(ast, env) do
      {:ok, arg, step} -> extract_pipeline_asts(arg, env, [step | acc])
      :error -> {ast, acc}
    end
  end

  defp split_call(ast = {_, meta, args}, env) when is_list(args) do
    case normalize_call_function(ast, env) do
      {Kernel, :|>, [left, right]} ->
        case normalize_call_function(right, env) do
          {V2, fun, args} -> {:ok, left, {fun, meta, args}}
          _ -> :error
        end

      {V2, fun, [arg | args]} ->
        {:ok, arg, {fun, meta, args}}

      _ ->
        :error
    end
  end

  defp split_call(_ast, _env), do: :error

  @doc """
  Resolves the module, function name and arity for a function call AST.

  ## Examples

      iex> normalize_call_function(quote(do: inspect(123)), __ENV__)
      {Kernel, :inspect, [123]}

      iex> normalize_call_function(quote(do: String.upcase("foo")), __ENV__)
      {String, :upcase, ["foo"]}

      iex> alias String, as: S
      iex> normalize_call_function(quote(do: S.upcase("foo")), __ENV__)
      {String, :upcase, ["foo"]}

      iex> normalize_call_function(quote(do: foo(123)), __ENV__)
      :error

  """
  def normalize_call_function({call, _, args}, env) do
    do_normalize_call_function(call, args, env)
  end

  defp do_normalize_call_function(name, args, env) when is_atom(name) do
    arity = length(args)

    case Macro.Env.lookup_import(env, {name, arity}) do
      [{fun_or_macro, module}] when fun_or_macro in [:function, :macro] -> {module, name, args}
      _ -> :error
    end
  end

  defp do_normalize_call_function({:., _, [{:__aliases__, _, _} = module, fun]}, args, env) do
    module = Macro.expand(module, env)
    {module, fun, args}
  end

  defp asts_to_steps([last], acc) do
    step = transform_step(last)
    [step | acc]
  end

  defp asts_to_steps([head | tail], acc) do
    step = transform_step(head)

    unless Step.spec(step).collect do
      asts_to_steps(tail, [step | acc])
    else
      {fun_with_arity, line} = fun_arity_and_line(head)
      raise "#{line}: Cannot call #{fun_with_arity} in the middle of a pipeline"
    end
  end

  defp transform_step({:map, _meta, [fun]}), do: %V2.Map{fun: fun}
  defp transform_step({:filter, _meta, [fun]}), do: %V2.Filter{fun: fun}
  defp transform_step({:sum, _meta, []}), do: %V2.Sum{}
  defp transform_step({:join, _meta, []}), do: V2.Join.new()
  defp transform_step({:join, _meta, [joiner]}), do: V2.Join.new(joiner)
  defp transform_step({:uniq, _meta, []}), do: V2.Uniq.new()
  defp transform_step({:dedup, _meta, []}), do: V2.Dedup.new()
  defp transform_step({:take, meta, [amount]}), do: V2.Take.new(amount, meta)
  defp transform_step({:drop, meta, [amount]}), do: V2.Drop.new(amount, meta)
  defp transform_step({:reverse, _meta, []}), do: V2.Reverse.new()
  defp transform_step({:reverse, _meta, [tail]}), do: V2.Reverse.new(tail)
  defp transform_step({:sort, _meta, []}), do: V2.Sort.new()
  defp transform_step({:sort, _meta, [sorter]}), do: V2.Sort.new(sorter)

  defp transform_step(ast) do
    {fun_with_arity, line} = fun_arity_and_line(ast)
    raise ArgumentError, "#{line}: Invalid function #{fun_with_arity}"
  end

  defp fun_arity_and_line({fun, meta, args}) do
    arity = length(args) + 1
    {"Enumancer.#{fun}/#{arity}", meta[:line]}
  end

  defp transpile_pipeline({first, steps = [last | _]}) do
    vars = init_vars(steps)

    initial_acc = Step.initial_acc(last)

    return =
      quote do
        unquote(vars.acc) = unquote(Step.return_acc(last, vars))
        unquote(vars.composite_acc)
      end

    body =
      Enum.reduce(steps, return, fn step, continue ->
        build_body(step, continue, vars)
      end)

    inits = for step <- steps, init = Step.init(step), do: init

    {module, reduce_fun} =
      if Enum.any?(steps, &Step.spec(&1).halt) do
        {__MODULE__, :reduce_while}
      else
        {Enum, :reduce}
      end

    quote do
      unquote_splicing(inits)
      unquote(vars.acc) = unquote(initial_acc)

      unquote(vars.composite_acc) =
        unquote(module).unquote(reduce_fun)(unquote(first), unquote(vars.composite_acc), fn
          unquote(vars.head), unquote(vars.composite_acc) -> unquote(body)
        end)

      unquote(Step.wrap(last, vars.acc))
    end
  end

  defp reduce_block(steps, args) do
    if Enum.any?(steps, &Step.spec(&1).halt) do
      quote do: reduce_while(unquote_splicing(args))
    else
      quote do: Enum.reduce(unquote_splicing(args))
    end
  end

  defp init_vars(steps) do
    extra_args = Enum.flat_map(steps, &Step.spec(&1).extra_args)

    [:head, :tail, :acc]
    |> Map.new(&{&1, Macro.unique_var(&1, nil)})
    |> Map.put(:extra_args, extra_args)
    |> add_composite_acc()
  end

  defp add_composite_acc(vars = %{acc: acc, extra_args: extra}) do
    composite_acc = composite_acc(acc, extra)
    Map.put(vars, :composite_acc, composite_acc)
  end

  defp composite_acc(acc, []), do: acc

  defp composite_acc(acc, extra) do
    quote do: {unquote(acc), unquote_splicing(extra)}
  end

  defp build_body(step, continue, vars) do
    Step.define_next_acc(step, vars, continue)
  end

  @compile {:inline, reduce_while_list: 3, reduce_while_range: 5}

  def reduce_while(enumerable, acc, fun) when is_function(fun, 2) do
    case enumerable do
      list when is_list(list) -> reduce_while_list(list, acc, fun)
      start..stop//step -> reduce_while_range(start, stop, step, acc, fun)
    end
  end

  defp reduce_while_list([], acc, _fun), do: acc

  defp reduce_while_list([h | t], acc, fun) do
    case fun.(h, acc) do
      {:__ENUMANCER_HALT__, acc} -> acc
      acc -> reduce_while_list(t, acc, fun)
    end
  end

  defp reduce_while_range(start, stop, step, acc, _fun)
       when (step > 0 and start > stop) or (step < 0 and start < stop),
       do: acc

  defp reduce_while_range(start, stop, step, acc, fun) do
    case fun.(start, acc) do
      {:__ENUMANCER_HALT__, acc} -> acc
      acc -> reduce_while_range(start + step, stop, step, acc, fun)
    end
  end
end
