use Protoss

defprotocol ManualDelegated do
  def fun(s)
  defdelegate(add(a, b))
end

defmodule ManualDelegationModule do
  use ManualDelegated

  defstruct []

  def fun(_), do: 47
  def add(b), do: 47 + b
end

defmodule DelegationTest do
  use ExUnit.Case, async: true

  test "basic delegation occurs" do
    assert 47 = ManualDelegated.fun(%ManualDelegationModule{})
    assert 48 = ManualDelegated.add(ManualDelegationModule, 1)
  end

  test "verify callbacks" do
    assert [fun: 1, add: 1] = ManualDelegated.behaviour_info(:callbacks)
  end
end
