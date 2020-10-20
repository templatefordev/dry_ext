defmodule Utils.StringTest do
  use ExUnit.Case

  test "length random string" do
    string_random = DryExt.Utils.String.random(7)
    assert String.length(string_random) == 7
  end
end
