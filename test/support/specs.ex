use Protoss

defprotocol Specs do
  @spec proto_fun(t) :: t
  def proto_fun(s)

  @spec delegation_fun(module, integer) :: integer
  defdelegate delegation_fun(module, integer)

  defdelegate unspeced_delegation(module, integer)
after
  @spec body_fun() :: integer
  def body_fun, do: 47
end
