defmodule V2.StepSpec do
  @enforce_keys [:fun]
  defstruct @enforce_keys
end

defprotocol V2.Step do
  def position(step)
  def extra_args(step)
  def init(step)
  def initial_acc(step)
  def define_next_acc(step, vars, continue)
  def return_acc(step, vars)
  def wrap(step, ast)
end

defmodule V2.Map do
  @enforce_keys [:fun]
  defstruct @enforce_keys
end

defimpl V2.Step, for: V2.Map do
  def position(_), do: :anywhere

  def extra_args(_), do: []
  def init(_), do: nil
  def initial_acc(_), do: []

  def define_next_acc(%{fun: fun}, vars, continue) do
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

defmodule V2.Filter do
  @enforce_keys [:fun]
  defstruct @enforce_keys
end

defimpl V2.Step, for: V2.Filter do
  def position(_), do: :anywhere

  def extra_args(_), do: []
  def init(_), do: nil
  def initial_acc(_), do: []

  def define_next_acc(%{fun: fun}, vars, continue) do
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

defmodule V2.Sum do
  defstruct []

  def new([]), do: %__MODULE__{}
end

defimpl V2.Step, for: V2.Sum do
  def position(_), do: :last

  def extra_args(_), do: []
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

defmodule V2.Join do
  @enforce_keys [:value, :joiner_var]
  defstruct @enforce_keys

  def new(), do: %__MODULE__{value: nil, joiner_var: nil}
  def new(""), do: new()
  def new(joiner), do: %__MODULE__{value: joiner, joiner_var: Macro.unique_var(:joiner, nil)}
end

defimpl V2.Step, for: V2.Join do
  def position(_), do: :last

  def extra_args(_), do: []

  def init(%V2.Join{value: nil}), do: nil

  def init(%V2.Join{value: value, joiner_var: var}) do
    quote do
      unquote(var) =
        case unquote(value) do
          joiner when is_binary(joiner) -> joiner
        end
    end
  end

  def initial_acc(_), do: []

  def define_next_acc(_, _vars, continue), do: continue

  def return_acc(%V2.Join{joiner_var: joiner}, vars) do
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

  def wrap(%V2.Join{joiner_var: nil}, ast) do
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

defmodule V2.Uniq do
  @enforce_keys [:map]
  defstruct @enforce_keys

  def new, do: %__MODULE__{map: Macro.unique_var(:uniq, nil)}
end

defimpl V2.Step, for: V2.Uniq do
  def position(_), do: :anywhere

  def extra_args(%V2.Uniq{map: map}), do: [map]

  def init(%V2.Uniq{map: map}) do
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

defmodule V2.Dedup do
  @enforce_keys [:previous]
  defstruct @enforce_keys

  def new, do: %__MODULE__{previous: Macro.unique_var(:previous, nil)}
end

defimpl V2.Step, for: V2.Dedup do
  def position(_), do: :anywhere

  def extra_args(%V2.Dedup{previous: previous}), do: [previous]

  def init(%V2.Dedup{previous: previous}) do
    quote do: unquote(previous) = :__ENUMANCER_RESERVED__
  end

  def initial_acc(_), do: []

  def define_next_acc(%V2.Dedup{previous: previous}, vars, continue) do
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

defmodule V2.Drop do
  @enforce_keys [:amount_var, :value]
  defstruct @enforce_keys

  def new(amount) do
    %__MODULE__{
      amount_var: Macro.unique_var(:amount, nil),
      value: amount
    }
  end
end

defimpl V2.Step, for: V2.Drop do
  def position(_), do: :anywhere

  def extra_args(%V2.Drop{amount_var: amount}), do: [amount]

  def init(%V2.Drop{amount_var: amount, value: value}) do
    quote do
      unquote(amount) =
        case unquote(value) do
          amount when is_integer(amount) and amount > 0 -> amount
        end
    end
  end

  def initial_acc(_), do: []

  def define_next_acc(%V2.Drop{amount_var: amount}, vars, continue) do
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

defmodule V2.Reverse do
  @enforce_keys [:tail]
  defstruct @enforce_keys

  def new(tail \\ []) do
    %__MODULE__{tail: tail}
  end
end

defimpl V2.Step, for: V2.Reverse do
  def position(_), do: :anywhere

  def extra_args(%V2.Reverse{}), do: []

  def init(_), do: nil

  def initial_acc(%V2.Reverse{tail: tail}) do
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

defmodule V2.Sort do
  # TODO: optimization: if only step, optimize by removing the loop
  # since this is a wrap only step!

  @enforce_keys [:sorter]
  defstruct @enforce_keys

  def new(sorter \\ :asc) do
    %__MODULE__{sorter: sorter}
  end
end

defimpl V2.Step, for: V2.Sort do
  def position(_), do: :anywhere

  def extra_args(_), do: []

  def init(_), do: nil

  def initial_acc(_), do: []

  def define_next_acc(_, _vars, continue), do: continue

  def return_acc(_, vars) do
    quote do
      [unquote(vars.head) | unquote(vars.acc)]
    end
  end

  def wrap(%V2.Sort{sorter: sorter}, ast) do
    case sorter do
      :asc -> quote do: Enum.sort(unquote(ast))
      _ -> quote do: Enum.sort(unquote(ast), unquote(sorter))
    end
  end
end
