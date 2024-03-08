use Protoss

defprotocol AfterFunction do
  def fun(s)
after
  def add(a, b) do
    a + b
  end
end

defmodule AfterFunctionModule do
  use AfterFunction

  defstruct []

  def fun(_), do: 47
end

defmodule AfterFunctionTest do
  use ExUnit.Case, async: true

  test "basic delegation occurs" do
    assert 47 = AfterFunction.fun(%AfterFunctionModule{})
  end

  test "after function works" do
    assert 48 = AfterFunction.add(1, 47)
  end
end
