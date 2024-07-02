defmodule SpecsTest do
  use ExUnit.Case, async: true

  setup do
    Code.Typespec.fetch_specs(Specs)
  end

  test "proto_fun specs assigned correctly inside the protocol", specs do
    assert [
             {:type, _, :fun,
              [{:type, _, :product, [{:user_type, _, :t, []}]}, {:user_type, _, :t, []}]}
           ] = Map.fetch!(specs, {:proto_fun, 1})
  end

  test "unspecced protocol function is not in the specs", specs do
    refute Map.has_key?(specs, {:unspeced_proto, 2})
  end

  test "delegation specs assigned correctly inside the protocol", specs do
    assert [
             {:type, _, :fun,
              [
                {:type, _, :product, [{:type, _, :module, []}, {:type, _, :integer, _}]},
                {:type, _, :integer, []}
              ]}
           ] = Map.fetch!(specs, {:delegation_fun, 2})
  end

  test "unspecced delegation function is not in the specs", specs do
    refute Map.has_key?(specs, {:unspeced_delegation, 2})
  end

  test "specs assigned correctly outside the protocol", specs do
    assert [{:type, _, :fun, [{:type, _, :product, []}, {:type, _, :integer, []}]}] =
             Map.fetch!(specs, {:body_fun, 0})
  end
end
