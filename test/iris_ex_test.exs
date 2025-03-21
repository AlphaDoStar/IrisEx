defmodule IrisExTest do
  use ExUnit.Case
  doctest IrisEx

  test "greets the world" do
    assert IrisEx.hello() == :world
  end
end
