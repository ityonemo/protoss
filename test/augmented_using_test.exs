use Protoss

defprotocol AugmentedUsing do
  def fun(s)
after
  defmacro __using__(opts) do
    if opts[:augmented] do
      quote do
        def augmented_fun, do: 47
      end
    end
  end
end

defmodule UnAugmented do
  use AugmentedUsing

  defstruct []

  def fun(_), do: 47
end

defmodule Augmented do
  use AugmentedUsing, augmented: true

  defstruct []

  def fun(_), do: augmented_fun()
end

defmodule AugmentedMacroTest do
  use ExUnit.Case, async: true

  test "unaugmented function doesn't invoke macro" do
    refute function_exported?(UnAugmented, :augmented_fun, 0)
  end

  test "after function works" do
    assert function_exported?(Augmented, :augmented_fun, 0)
    assert 47 = AugmentedUsing.fun(%Augmented{})
  end
end