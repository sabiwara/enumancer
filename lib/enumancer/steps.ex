defmodule Enumancer.StepSpec do
  defstruct collect: false, extra_args: [], halt: false
end

defprotocol Enumancer.Step do
  def spec(step)
  def init(step)
  def initial_acc(step)
  def define_next_acc(step, vars, continue)
  def return_acc(step, vars)
  def wrap(step, ast)
end

defmodule Enumancer.Map do
  @enforce_keys [:fun]
  defstruct @enforce_keys
end

defimpl Enumancer.Step, for: Enumancer.Map do
  def spec(_), do: %Enumancer.StepSpec{}

  def extra_args(_), do: []
  def init(_), do: nil
  def initial_acc(_), do: []

  def define_next_acc(%Enumancer.Map{fun: fun}, vars, continue) do
    quote do
      unquote(vars.head) = unquote(fun).(unquote(vars.head))
      unquote(continue)
    end
  end

  def return_acc(_, vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  def wrap(_, ast) do
    quote do: :lists.reverse(unquote(ast))
  end
end

defmodule Enumancer.Filter do
  @enforce_keys [:fun]
  defstruct @enforce_keys
end

defimpl Enumancer.Step, for: Enumancer.Filter do
  def spec(_), do: %Enumancer.StepSpec{}

  def init(_), do: nil
  def initial_acc(_), do: []

  def define_next_acc(%Enumancer.Filter{fun: fun}, vars, continue) do
    quote do
      if unquote(fun).(unquote(vars.head)) do
        unquote(continue)
      else
        unquote(vars.composite_acc)
      end
    end
  end

  def return_acc(_, vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  def wrap(_, ast) do
    quote do: :lists.reverse(unquote(ast))
  end
end

defmodule Enumancer.Sum do
  defstruct []

  def new([]), do: %__MODULE__{}
end

defimpl Enumancer.Step, for: Enumancer.Sum do
  def spec(_), do: %Enumancer.StepSpec{collect: true}

  def init(_), do: nil
  def initial_acc(_), do: 0

  def define_next_acc(_, _, continue), do: continue

  def return_acc(_, vars) do
    quote do
      unquote(vars.head) + unquote(vars.acc)
    end
  end

  def wrap(_, ast), do: ast
end

defmodule Enumancer.Join do
  @enforce_keys [:value, :joiner_var]
  defstruct @enforce_keys

  def new(), do: %__MODULE__{value: nil, joiner_var: nil}
  def new(""), do: new()
  def new(joiner), do: %__MODULE__{value: joiner, joiner_var: Macro.unique_var(:joiner, nil)}
end

defimpl Enumancer.Step, for: Enumancer.Join do
  def spec(_), do: %Enumancer.StepSpec{collect: true}

  def init(%Enumancer.Join{value: nil}), do: nil

  def init(%Enumancer.Join{value: value, joiner_var: var}) do
    quote do
      unquote(var) =
        case unquote(value) do
          joiner when is_binary(joiner) -> joiner
        end
    end
  end

  def initial_acc(_), do: []

  def define_next_acc(_, _vars, continue), do: continue

  def return_acc(%Enumancer.Join{joiner_var: joiner}, vars) do
    maybe_joiner = if joiner, do: [joiner], else: []

    quote do
      string =
        case unquote(vars.head) do
          binary when is_binary(binary) -> binary
          other -> String.Chars.to_string(other)
        end

      [unquote_splicing(maybe_joiner), string | unquote(vars.acc)]
    end
  end

  def wrap(%Enumancer.Join{joiner_var: nil}, ast) do
    quote do
      :lists.reverse(unquote(ast)) |> IO.iodata_to_binary()
    end
  end

  def wrap(_, ast) do
    quote do
      case unquote(ast) do
        [] -> ""
        [_ | tail] -> :lists.reverse(tail) |> IO.iodata_to_binary()
      end
    end
  end
end

defmodule Enumancer.Uniq do
  @enforce_keys [:map]
  defstruct @enforce_keys

  def new, do: %__MODULE__{map: Macro.unique_var(:uniq, nil)}
end

defimpl Enumancer.Step, for: Enumancer.Uniq do
  def spec(%Enumancer.Uniq{map: map}), do: %Enumancer.StepSpec{extra_args: [map]}

  def init(%Enumancer.Uniq{map: map}) do
    quote do: unquote(map) = %{}
  end

  def initial_acc(_), do: []

  def define_next_acc(%{map: map}, vars, continue) do
    quote do
      case unquote(map) do
        %{^unquote(vars.head) => _} ->
          unquote(vars.composite_acc)

        _ ->
          unquote(map) = Map.put(unquote(map), unquote(vars.head), [])
          unquote(continue)
      end
    end
  end

  def return_acc(_, vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  def wrap(_, ast) do
    quote do: :lists.reverse(unquote(ast))
  end
end

defmodule Enumancer.Dedup do
  @enforce_keys [:previous]
  defstruct @enforce_keys

  def new, do: %__MODULE__{previous: Macro.unique_var(:previous, nil)}
end

defimpl Enumancer.Step, for: Enumancer.Dedup do
  def spec(%Enumancer.Dedup{previous: previous}), do: %Enumancer.StepSpec{extra_args: [previous]}

  def init(%Enumancer.Dedup{previous: previous}) do
    quote do: unquote(previous) = :__ENUMANCER_RESERVED__
  end

  def initial_acc(_), do: []

  def define_next_acc(%Enumancer.Dedup{previous: previous}, vars, continue) do
    quote do
      case unquote(vars.head) do
        ^unquote(previous) ->
          unquote(vars.composite_acc)

        _ ->
          unquote(previous) = unquote(vars.head)
          unquote(continue)
      end
    end
  end

  def return_acc(_, vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  def wrap(_, ast) do
    quote do: :lists.reverse(unquote(ast))
  end
end

defmodule Enumancer.Take do
  @enforce_keys [:amount_var, :value, :line]
  defstruct @enforce_keys

  def new(amount, meta) do
    %__MODULE__{
      amount_var: Macro.unique_var(:amount, nil),
      value: amount,
      line: Keyword.fetch!(meta, :line)
    }
  end

  def validate_amount(amount) when is_integer(amount) and amount >= 0, do: amount
end

defimpl Enumancer.Step, for: Enumancer.Take do
  def spec(%Enumancer.Take{amount_var: amount}) do
    %Enumancer.StepSpec{extra_args: [amount], halt: true}
  end

  def init(%Enumancer.Take{amount_var: amount, value: value, line: line}) do
    quote line: line do
      unquote(amount) = Enumancer.Take.validate_amount(unquote(value))
    end
  end

  def initial_acc(_), do: []

  def define_next_acc(%Enumancer.Take{amount_var: amount}, vars, continue) do
    quote do
      case unquote(amount) do
        amount when amount > 0 ->
          unquote(amount) = amount - 1
          unquote(continue)

        _ ->
          {:__ENUMANCER_HALT__, unquote(vars.composite_acc)}
      end
    end
  end

  def return_acc(_, vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  def wrap(_, ast) do
    quote do: :lists.reverse(unquote(ast))
  end
end

defmodule Enumancer.Drop do
  @enforce_keys [:amount_var, :value, :line]
  defstruct @enforce_keys

  def new(amount, meta) do
    %__MODULE__{
      amount_var: Macro.unique_var(:amount, nil),
      value: amount,
      line: Keyword.fetch!(meta, :line)
    }
  end

  def validate_amount(amount) when is_integer(amount) and amount >= 0, do: amount
end

defimpl Enumancer.Step, for: Enumancer.Drop do
  def spec(%Enumancer.Drop{amount_var: amount}), do: %Enumancer.StepSpec{extra_args: [amount]}

  def extra_args(%Enumancer.Drop{amount_var: amount}), do: [amount]

  def init(%Enumancer.Drop{amount_var: amount, value: value, line: line}) do
    quote line: line do
      unquote(amount) = Enumancer.Drop.validate_amount(unquote(value))
    end
  end

  def initial_acc(_), do: []

  def define_next_acc(%Enumancer.Drop{amount_var: amount}, vars, continue) do
    quote do
      case unquote(amount) do
        amount when amount > 0 ->
          unquote(amount) = amount - 1
          unquote(vars.composite_acc)

        _ ->
          unquote(continue)
      end
    end
  end

  def return_acc(_, vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  def wrap(_, ast) do
    quote do: :lists.reverse(unquote(ast))
  end
end

defmodule Enumancer.Reverse do
  @enforce_keys [:tail]
  defstruct @enforce_keys

  def new(tail \\ []) do
    %__MODULE__{tail: tail}
  end
end

defimpl Enumancer.Step, for: Enumancer.Reverse do
  def spec(_), do: %Enumancer.StepSpec{}

  def init(_), do: nil

  def initial_acc(%Enumancer.Reverse{tail: tail}) do
    if is_list(tail) do
      tail
    else
      quote do: Enum.to_list(unquote(tail))
    end
  end

  def define_next_acc(_, _vars, continue), do: continue

  def return_acc(_, vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  def wrap(_, ast), do: ast
end

defmodule Enumancer.Sort do
  # TODO: optimization: if only step, optimize by removing the loop
  # since this is a wrap only step!

  @enforce_keys [:sorter]
  defstruct @enforce_keys

  def new(sorter \\ :asc) do
    %__MODULE__{sorter: sorter}
  end
end

defimpl Enumancer.Step, for: Enumancer.Sort do
  def spec(_), do: %Enumancer.StepSpec{collect: true}

  def init(_), do: nil

  def initial_acc(_), do: []

  def define_next_acc(_, _vars, continue), do: continue

  def return_acc(_, vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  def wrap(%Enumancer.Sort{sorter: sorter}, ast) do
    case sorter do
      :asc -> quote do: Enum.sort(unquote(ast))
      _ -> quote do: Enum.sort(unquote(ast), unquote(sorter))
    end
  end
end

defmodule Enumancer.FlatMap do
  @enforce_keys [:fun]
  defstruct @enforce_keys

  def new(), do: %__MODULE__{fun: quote(do: & &1)}
  def new(fun), do: %__MODULE__{fun: fun}
end

defimpl Enumancer.Step, for: Enumancer.FlatMap do
  def spec(_), do: %Enumancer.StepSpec{}

  def extra_args(_), do: []
  def init(_), do: nil
  def initial_acc(_), do: []

  def define_next_acc(%{fun: fun}, vars, continue) do
    # TODO: should use reduce_while
    quote do
      Enum.reduce(unquote(fun).(unquote(vars.head)), unquote(vars.composite_acc), fn
        unquote(vars.head), unquote(vars.composite_acc) ->
          unquote(continue)
      end)
    end
  end

  def return_acc(_, vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  def wrap(_, ast) do
    quote do: :lists.reverse(unquote(ast))
  end
end
