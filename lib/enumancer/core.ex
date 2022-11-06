defmodule Enumancer.Core do
  alias Enumancer.MacroHelpers
  alias Enumancer.Step
  alias Enumancer.Steps

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
    case MacroHelpers.normalize_call_function(ast, env) do
      {Kernel, :|>, [left, right]} ->
        case MacroHelpers.normalize_call_function(right, env) do
          {Enumancer, fun, args} -> {:ok, left, {fun, meta, args}}
          _ -> :error
        end

      {Enumancer, fun, [arg | args]} ->
        {:ok, arg, {fun, meta, args}}

      _ ->
        :error
    end
  end

  defp split_call(_ast, _env), do: :error

  defp asts_to_steps([last], acc) do
    step = Steps.transform_step(last)
    [step | acc]
  end

  defp asts_to_steps([head | tail], acc) do
    step = Steps.transform_step(head)

    unless Step.spec(step).collect do
      asts_to_steps(tail, [step | acc])
    else
      {fun_with_arity, line} = MacroHelpers.fun_arity_and_line(head)
      raise "#{line}: Cannot call #{fun_with_arity} in the middle of a pipeline"
    end
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
