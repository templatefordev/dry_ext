defmodule DryExt.Utils.MapTest do
  use ExUnit.Case
  doctest DryExt.Utils.Map

  import DryExt.Utils.Map

  test "|||/2 return merge map" do
    map = %{one: "1"} ||| %{two: "2"}
    assert map == %{one: "1", two: "2"}
  end
end
