use Protoss

defprotocol Docs do
  @doc "this is the foo function"
  def foo(s)
after
  @doc "this is the bar function"
  def bar, do: 47
end
