defmodule DryExtTest do
  use ExUnit.Case
  doctest DryExt

  test "greets the world" do
    assert DryExt.hello() == :world
  end
end
