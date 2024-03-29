use Protoss

defprotocol Specs do
  @spec foo(t) :: t
  def foo(s)
after
  @spec bar() :: integer
  def bar, do: 47
end
