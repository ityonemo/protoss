defmodule DocsTest do
  use ExUnit.Case, async: true

  test "docs assigned correctly inside the protocol" do
    assert {_, _, _, _, _, _, docs} = Code.fetch_docs(Docs)

    assert {_, _, _, %{"en" => "this is the foo function"}, _} =
             List.keyfind(docs, {:function, :foo, 1}, 0)
  end

  test "docs assigned correctly outside the protocol" do
    assert {_, _, _, _, _, _, docs} = Code.fetch_docs(Docs)

    assert {_, _, _, %{"en" => "this is the bar function"}, _} =
             List.keyfind(docs, {:function, :bar, 0}, 0)
  end
end
