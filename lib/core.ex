defmodule V2.Core do
  alias V2.Step

  def inspect_ast(ast) do
    ast |> Macro.to_string() |> IO.puts()
    ast
  end

  defmacro def_enum({fun, meta, [enum | args]}) do
    quote do
      defmacro unquote(fun)(unquote_splicing([enum | args])) do
        pipeline(unquote(enum), __CALLER__, [{unquote(fun), unquote(meta), unquote(args)}])
      end
    end
  end

  def pipeline(ast, env, acc) do
    {first, raw_steps} = extract_pipeline(ast, env, acc)

    raw_steps
    |> prepare_pipeline([])
    |> transpile_pipeline(first)
  end

  defp extract_pipeline(ast, env, acc) do
    case split_call(ast, env) do
      {:ok, arg, step} -> extract_pipeline(arg, env, [step | acc])
      :error -> {ast, acc}
    end
  end

  defp split_call(ast = {_, meta, _}, env) do
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

  defp do_normalize_call_function({:., _, [{:__aliases__, meta, modules}, fun]}, args, _env) do
    module = meta[:alias] || Module.concat(modules)
    {module, fun, args}
  end

  defp prepare_pipeline([last], acc) do
    step = transform_step(last)
    [step | acc]
  end

  defp prepare_pipeline([head | tail], acc) do
    step = transform_step(head)

    case Step.position(step) do
      :anywhere ->
        prepare_pipeline(tail, [step | acc])

      :last ->
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
  defp transform_step({:drop, _meta, [amount]}), do: V2.Drop.new(amount)
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

  defp transpile_pipeline(steps = [last | _], first) do
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

    quote do
      unquote_splicing(inits)
      unquote(vars.acc) = unquote(initial_acc)

      unquote(vars.composite_acc) =
        Enum.reduce(unquote(first), unquote(vars.composite_acc), fn
          unquote(vars.head), unquote(vars.composite_acc) -> unquote(body)
        end)

      unquote(Step.wrap(last, vars.acc))
    end
  end

  defp init_vars(steps) do
    extra_args = Enum.flat_map(steps, &Step.extra_args(&1))

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
end
