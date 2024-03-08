use Protoss

defprotocol AutoDelegate do
  def fun(s)
end

defmodule AutoDelegationModule do
  use AutoDelegate

  defstruct []

  def fun(_), do: 47
end

defmodule AutoDelegateTest do
  use ExUnit.Case, async: true

  test "basic delegation occurs" do
    assert 47 = AutoDelegate.fun(%AutoDelegationModule{})
  end
end
