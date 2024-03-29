use Protoss

defprotocol AfterDefHeader do
  def fun(s)
after
  def add(a, b \\ 47)
  def add(a, b) do
    a + b
  end
end

defmodule AfterDefHeaderModule do
  use AfterDefHeader

  defstruct []

  def fun(_), do: 47
end

defmodule AfterDefHeaderTest do
  use ExUnit.Case, async: true

  test "after function works" do
    assert 48 = AfterDefHeader.add(1)
  end
end
