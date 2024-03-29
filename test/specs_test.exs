defmodule SpecsTest do
  use ExUnit.Case, async: true

  test "spces assigned correctly inside the protocol" do
    assert {:ok, specs} = Code.Typespec.fetch_specs(Specs)

    assert {_,
            [
              {:type, _, :fun,
               [{:type, _, :product, [{:user_type, _, :t, []}]}, {:user_type, _, :t, []}]}
            ]} = List.keyfind(specs, {:foo, 1}, 0)
  end

  test "spces assigned correctly outside the protocol" do
    assert {:ok, specs} = Code.Typespec.fetch_specs(Specs)

    assert {_, [{:type, _, :fun, [{:type, _, :product, []}, {:type, _, :integer, []}]}]} =
             List.keyfind(specs, {:bar, 0}, 0)
  end
end
