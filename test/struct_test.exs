use Protoss

defprotocol StructProtocol do
  def fun(s)
after
  defstruct []
end

defimpl StructProtocol, for: StructProtocol do
  def fun(_), do: 47
end

defmodule StructTest do
  use ExUnit.Case, async: true

  test "basic delegation occurs" do
    assert 47 = StructProtocol.fun(%StructProtocol{})
  end
end
