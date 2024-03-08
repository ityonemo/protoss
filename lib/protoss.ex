defmodule Protoss do
  defmacro __using__(_) do
    quote do
      import Kernel, except: [defprotocol: 2]
      import Protoss, only: [defprotocol: 2, defdelegate: 1]
    end
  end

  defmacro defprotocol(proto_module, [{:do, body} | rest]) do
    delegations = Macro.escape(scan_delegation(body))

    after_content = Keyword.get(rest, :after, [])
    after_callbacks = scan_callbacks(after_content)
    after_code = Macro.escape(after_content)

    extended =
      quote do
        @before_compile Protoss
        Module.put_attribute(__MODULE__, :__protoss_delegations__, unquote(delegations))
        Module.put_attribute(__MODULE__, :__protoss_after_content__, unquote(after_code))
        Module.put_attribute(__MODULE__, :__protoss_after_callbacks__, unquote(after_callbacks))
        unquote(body)
      end

    quote do
      Kernel.defprotocol(unquote(proto_module), do: unquote(extended))
    end
  end

  defmacro defdelegate(_), do: []

  defmacro __before_compile__(%{module: module}) do
    # this before_compile is called in the protocol body, so we should
    # be generating at a minimum, the `using` content.

    delegations =
      module
      |> Module.get_attribute(:__protoss_delegations__)
      |> Enum.group_by(&elem(elem(&1, 0), 0), &{elem(elem(&1, 0), 1), elem(&1, 1)})
      |> Map.put_new(:module, [])

    protocol_delegations = Macro.escape(delegations.protocol)

    module_delegations =
      Enum.map(delegations.module, fn {name, [module | rest] = params} ->
        quote do
          def unquote(name)(unquote_splicing(params)) do
            unquote(module).unquote(name)(unquote_splicing(rest))
          end
        end
      end)

    module_delegations_callbacks =
      Enum.map(delegations.module, fn {name, params} ->
        params_types =
          List.duplicate(
            quote do
              term()
            end,
            length(params) - 1
          )

        quote do
          @callback unquote(name)(unquote_splicing(params_types)) :: term()
        end
      end)

    after_content = Module.get_attribute(module, :__protoss_after_content__)
    after_callbacks = Module.get_attribute(module, :__protoss_after_callbacks__)

    quote do
      import Kernel

      unquote_splicing(module_delegations_callbacks)
      unquote_splicing(module_delegations)
      unquote(after_content)

      defmacro __using__(_) do
        protocol = __MODULE__
        caller = __CALLER__.module

        delegates =
          Enum.map(unquote(protocol_delegations), fn
            {fun, params} ->
              quote do
                defdelegate unquote(fun)(unquote_splicing(params)), to: unquote(caller)
              end
          end)

        suppress_delegations =
          Enum.map(unquote(Macro.escape(delegations.module)), fn
            {fun, params} ->
              Protoss._empty_function(fun, length(params) - 1)
          end)

        suppress_callbacks = 
          Enum.map(unquote(after_callbacks), fn 
            {fun, param_count} ->
              Protoss._empty_function(fun, param_count)
          end)

        quote do
          defimpl unquote(protocol) do
            unquote(delegates)
            # here we need to suppress callbacks that were declared as a part of basic protocols
            unquote(suppress_delegations)
          end
        end
      end
    end
  end

  defp scan_delegation(ast) do
    {_, defs} =
      Macro.prewalk(ast, [], fn
        {:def, _, [{name, _, args}]} = ast, so_far ->
          {ast, [{{:protocol, name}, args} | so_far]}

        {:defdelegate, _, [{name, _, args}]} = ast, so_far ->
          {ast, [{{:module, name}, args} | so_far]}

        ast, so_far ->
          {ast, so_far}
      end)

    defs
  end

  defp scan_callbacks(ast) do
    {_, cbs} =
      Macro.prewalk(ast, [], fn
        {:@, _, [{:callback, _, [{:"::", _ , [{name, _, count} | _]}]}]}, so_far ->
          {ast, [{name, length(count)} | so_far]}
        ast, so_far ->
          {ast, so_far}
      end)

    cbs
  end

  @doc false
  def _empty_function(name, args_count) do
    empty_args =
      List.duplicate(
        quote do
          _
        end,
        args_count
      )

    quote do
      def unquote(name)(unquote_splicing(empty_args)) do
        raise "unreachable"
      end
    end
  end
end
