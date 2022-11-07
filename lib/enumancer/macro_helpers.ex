defmodule Enumancer.MacroHelpers do
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

  def fun_arity_and_line({fun, meta, args}) do
    arity = length(args) + 1
    {"Enumancer.#{fun}/#{arity}", meta[:line]}
  end

  def remove_useless_assigns(ast) do
    Macro.postwalk(ast, fn
      {:__block__, _, [{:=, _, [var, node]}, var]} -> node
      node -> node
    end)
  end

  def to_exprs({:__block__, _, exprs}), do: exprs
  def to_exprs(expr), do: [expr]

  def inspect_ast(ast) do
    ast |> Macro.to_string() |> IO.puts()
    ast
  end
end
