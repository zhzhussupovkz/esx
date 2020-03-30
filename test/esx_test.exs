defmodule EsxTest do
  use ExUnit.Case
  doctest Esx

  test "greets the world" do
    assert Esx.hello() == :world
  end
end
