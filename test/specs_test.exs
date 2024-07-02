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

  test "delegation specs assigned correctly inside the protocol", specs do
    assert [
              {:type, _, :fun,
               [{:type, _, :product, [{:user_type, _, :t, []}]}, {:user_type, _, :t, []}]}
            ] = Map.fetch!(specs, {:delegation_fun, 1})
  end


  test "specs assigned correctly outside the protocol", specs do
    assert [{:type, _, :fun, [{:type, _, :product, []}, {:type, _, :integer, []}]}] =
             Map.fetch!(specs, {:body_fun, 0})
  end
end
