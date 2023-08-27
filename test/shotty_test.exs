defmodule ShottyTest do
  use ExUnit.Case
  doctest Shotty

  test "greets the world" do
    assert Shotty.hello() == :world
  end
end
