defmodule RiotClientTest do
  use ExUnit.Case
  doctest RiotClient

  test "greets the world" do
    assert RiotClient.hello() == :world
  end
end
