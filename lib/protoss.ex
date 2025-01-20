defmodule Protoss do
  @moduledoc """
  Protoss is a utility library that allows you to define protocols implementations
  which automatically delegate back to the module that is the caller of the protocol.

  ### Automatic delegation of protocol functions

  The primary purpose of `Protoss` is to automatically delegate protocol functions.
  As an example, here is standard elixir code for implementing a protocol:

  ```elixir
  defprotocol Proto do
    def unwrap(term)
  end

  defmodule MyStruct do
    defstruct [:value]
    defimpl Proto do
      def unwrap(term), do: term.value
    end
  end
  ```

  Protoss makes this easier to understand by hiding the `defimpl` boilerplate module.
  This is a natural fit for Elixir's convention of having module functions whose
  first parameter is the module's datatype.

  ```elixir
  use Protoss
  defprotocol Proto do
    def unwrap(term)
  end

  defmodule MyStruct do
    use Proto
    defstruct [:value]
    def unwrap(term), do: term.value
  end
  ```

  ### Directly delegated functions.

  Protoss also allows you to define functions that get directly delegated to the
  implementation module, that are then logically associated with the protocol, and
  whose existence is checked by the compiler using the protocol behaviour.

  A common use case would be a `from_json` function which reifies json data into a
  struct.

  #### Example:

  ```elixir
  use Protoss
  defprotocol Proto do
    def unwrap(term)
    defdelegate from_json(module, json)
  end

  defmodule MyStruct do
    use Proto
    defstruct [:value]
    def unwrap(term), do: term.value

    # NOTE the arity of the function
    def from_json(%{"value" => v}), do: %__MODULE__{value: v}
  end
  ```

  ### Protocol body functions

  Finally, protoss allows you to write arbitrary functions in the protocol body
  that aren't necessarily part of the protocol itself, using the `after` keyword.
  This could be useful to reduce code duplication if you have a common processing
  step that must occur in conjunction with a pseudo-private protocol function,
  or even if you simply have a thematically relevant function that you would like
  to incorporate  into the same namespace.

  ```elixir
  use Protoss
  defprotocol Proto do
    def _unwrap_impl(term)
  after
    def unwrap(struct) do
      struct
      |> _unwrap_impl()
      |> SomeOtherModule.process()
    end
  end

  defmodule MyStruct do
    use Proto
    defstruct [:value]
    def _unwrap_impl(term), do: term.value
  end
  ```
  """

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

    specs = Module.get_attribute(module, :spec)

    module_delegations_callbacks =
      Enum.map(delegations.module, fn {name, delegation_params} ->
        spec =
          Enum.flat_map(specs, fn
            {:spec, {:"::", _, [{^name, _, spec_params} | _]} = spec_ast, _}
            when length(spec_params) == length(delegation_params) ->
              [spec_ast]

            _ ->
              []
          end)

        case spec do
          [] ->
            params_types =
              List.duplicate(
                quote do
                  term()
                end,
                length(delegation_params) - 1
              )

            quote do
              @callback unquote(name)(unquote_splicing(params_types)) :: term()
            end

          specs ->
            Enum.map(specs, fn {:"::", meta1, [{^name, meta2, spec_params} | rest]} ->
              new_callback = {:"::", meta1, [{name, meta2, tl(spec_params)} | rest]}

              quote do
                @callback unquote(new_callback)
              end
            end)
        end
      end)

    after_content = Module.get_attribute(module, :__protoss_after_content__)
    after_callbacks = Module.get_attribute(module, :__protoss_after_callbacks__)

    quote do
      import Protocol, only: []
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
          @behaviour unquote(protocol)
          defimpl unquote(protocol) do
            unquote(delegates)
            # here we need to suppress callbacks that were declared as a part of basic protocols
            unquote(suppress_delegations)
            unquote(suppress_callbacks)
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
        {:@, _, [{:callback, _, [{:"::", _, [{name, _, count} | _]}]}]} = ast, so_far ->
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
