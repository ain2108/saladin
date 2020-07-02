defmodule SaladinTest do
  use ExUnit.Case
  doctest Saladin

  test "greets the world" do
    assert Saladin.hello() == :world
  end
end
