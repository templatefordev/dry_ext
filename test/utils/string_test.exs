defmodule DryExt.Utils.StringTest do
  use ExUnit.Case

  test "random/1 return random string by length" do
    string_random = DryExt.Utils.String.random(7)
    assert String.length(string_random) == 7
  end
end
