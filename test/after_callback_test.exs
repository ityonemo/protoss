use Protoss

defprotocol AfterCallback do
  def fun(s)
after
  @callback cb() :: term
end

defmodule AfterCallbackModule do
  use AfterCallback

  defstruct []

  def fun(_), do: 47
  def cb, do: 47
end

defmodule AfterCallbackTest do
  use ExUnit.Case, async: true

  test "basic delegation occurs" do
    assert 47 = AfterCallback.fun(%AfterCallbackModule{})
    assert 47 = AfterCallbackModule.cb()
  end
end
