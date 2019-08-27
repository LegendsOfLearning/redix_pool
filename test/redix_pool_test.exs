defmodule RedixPoolTest do
  use ExUnit.Case
  doctest RedixPool

  alias RedixPool, as: Redix

  setup do
    RedixPool.start(:normal, [pool_name: :test_pool])
    Redix.command(:test_pool, ["FLUSHDB"])
    :ok
  end

  test "basic command method" do
    assert Redix.command(:test_pool, ["SET", "foo", "bar"]) == {:ok, "OK"}
    assert Redix.command(:test_pool, ["GET", "foo"]) == {:ok, "bar"}

    assert Redix.command(:test_pool, ["HSET", "foobar", "field", "value"]) == {:ok, 1}
    assert Redix.command(:test_pool, ["HGET", "foobar", "field"]) == {:ok, "value"}
  end

  test "basic command! method" do
    assert Redix.command!(:test_pool, ["SET", "foo", "bar"]) == "OK"
    assert Redix.command!(:test_pool, ["GET", "foo"]) == "bar"

    assert Redix.command!(:test_pool, ["HSET", "foobar", "field", "value"]) == 1
    assert Redix.command!(:test_pool, ["HGET", "foobar", "field"]) == "value"
  end

  test "basic pipeline method" do
    assert Redix.pipeline(:test_pool, [["SET", "foo", "bar"],
                           ["SET", "baz", "bat"]]) == {:ok, ["OK", "OK"]}
    assert Redix.command(:test_pool, ["GET", "foo"]) == {:ok, "bar"}
    assert Redix.command(:test_pool, ["GET", "baz"]) == {:ok, "bat"}

    assert Redix.pipeline(:test_pool, [["HSET", "foobar", "foo", "bar"],
                           ["HSET", "foobar", "baz", "bat"]]) == {:ok, [1, 1]}
    assert Redix.command(:test_pool, ["HGET", "foobar", "foo"]) == {:ok, "bar"}
    assert Redix.command(:test_pool, ["HGET", "foobar", "baz"]) == {:ok, "bat"}
  end

  test "basic pipeline! method" do
    assert Redix.pipeline!(:test_pool, [["SET", "foo", "bar"],
                            ["SET", "baz", "bat"]]) == ["OK", "OK"]
    assert Redix.command(:test_pool, ["GET", "foo"]) == {:ok, "bar"}
    assert Redix.command(:test_pool, ["GET", "baz"]) == {:ok, "bat"}

    assert Redix.pipeline!(:test_pool, [["HSET", "foobar", "foo", "bar"],
                            ["HSET", "foobar", "baz", "bat"]]) == [1, 1]
    assert Redix.command(:test_pool, ["HGET", "foobar", "foo"]) == {:ok, "bar"}
    assert Redix.command(:test_pool, ["HGET", "foobar", "baz"]) == {:ok, "bat"}
  end
end
