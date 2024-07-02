defmodule CallbacksTest do
  use ExUnit.Case, async: true

  setup do
    Code.Typespec.fetch_callbacks(Specs)
  end

  test "callbacks assigned correctly inside the protocol", callbacks do
    assert [
             {:type, _, :fun,
              [{:type, _, :product, [{:user_type, _, :t, []}]}, {:user_type, _, :t, []}]}
           ] = Map.fetch!(callbacks, {:proto_fun, 1})
  end

  test "unspecced protocol function gets callback assigned correctly", callbacks do
    assert [
             {:type, _, :fun,
              [
                {:type, _, :product, [{:user_type, _, :t, []}, {:type, _, :term, []}]},
                {:type, _, :term, []}
              ]}
           ] = Map.fetch!(callbacks, {:unspeced_proto, 2})
  end

  test "module delegations assigned correctly inside the protocol (note, missing one param)",
       callbacks do
    assert [
             {:type, _, :fun,
              [{:type, _, :product, [{:type, _, :integer, []}]}, {:type, _, :integer, []}]}
           ] = Map.fetch!(callbacks, {:delegation_fun, 1})
  end

  test "module delegations with no information get assigned term (note, missing one param)",
       callbacks do
    assert [
             {:type, _, :fun,
              [{:type, _, :product, [{:type, _, :term, []}]}, {:type, _, :term, []}]}
           ] = Map.fetch!(callbacks, {:unspeced_delegation, 1})
  end

  test "an outside function does not generate a callback", callbacks do
    refute Map.has_key?(callbacks, {:body_fun, 1})
  end
end
