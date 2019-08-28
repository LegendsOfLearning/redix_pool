defmodule RedixPoolTest do
  use ExUnit.Case, async: true
  doctest RedixPool

  alias RedixPool, as: Redix

  setup do
    RedixPool.start(:normal, [pool_name: :test_pool])
    Redix.command(:test_pool, ["FLUSHDB"])
    :ok
  end

  def rand_key(key), do: "#{key}_#{SecureRandom.urlsafe_base64(16)}"
  def rand_key(), do: rand_key("test")

  test "RedixPool.command/2" do
    {key, value} = {rand_key(), rand_key()}
    assert Redix.command(:test_pool, ["SET", key, value]) == {:ok, "OK"}
    assert Redix.command(:test_pool, ["GET", key]) == {:ok, value}

    {hashkey, key, value} = {rand_key(), rand_key(), rand_key()}
    assert Redix.command(:test_pool, ["HSET", hashkey, key, value]) == {:ok, 1}
    assert Redix.command(:test_pool, ["HGET", hashkey, key]) == {:ok, value}
  end

  test "RedixPool.command!/2" do
    {key, value} = {rand_key(), rand_key()}
    assert Redix.command!(:test_pool, ["SET", key, value]) == "OK"
    assert Redix.command!(:test_pool, ["GET", key]) == value

    {hashkey, key, value} = {rand_key(), rand_key(), rand_key()}
    assert Redix.command!(:test_pool, ["HSET", hashkey, key, value]) == 1
    assert Redix.command!(:test_pool, ["HGET", hashkey, key]) == value
  end

  test "RedixPool.pipeline/2" do
    {k1, v1} = {rand_key(), rand_key()}
    {k2, v2} = {rand_key(), rand_key()}
    assert Redix.pipeline(:test_pool,
      [["SET", k1, v1], ["SET", k2, v2]]) == {:ok, ["OK", "OK"]}
    assert Redix.command(:test_pool, ["GET", k1]) == {:ok, v1}
    assert Redix.command(:test_pool, ["GET", k1]) == {:ok, v2}

    hash = rand_key()
    {k1, v1} = {rand_key(), rand_key()}
    {k2, v2} = {rand_key(), rand_key()}
    assert Redix.pipeline(:test_pool,
      [["HSET", hash, k1, v1], ["HSET", hash, k2, v2]]) == {:ok, [1, 1]}
    assert Redix.command(:test_pool, ["HGET", hash, k1]) == {:ok, v1}
    assert Redix.command(:test_pool, ["HGET", hash, k2]) == {:ok, v2}
  end

  test "RedixPool.pipeline!/2" do
    {k1, v1} = {rand_key(), rand_key()}
    {k2, v2} = {rand_key(), rand_key()}
    assert Redix.pipeline!(:test_pool,
      [["SET", k1, v1], ["SET", k2, v2]]) == ["OK", "OK"]
    assert Redix.command(:test_pool, ["GET", k1]) == {:ok, v1}
    assert Redix.command(:test_pool, ["GET", k1]) == {:ok, v2}

    hash = rand_key()
    {k1, v1} = {rand_key(), rand_key()}
    {k2, v2} = {rand_key(), rand_key()}
    assert Redix.pipeline!(:test_pool,
      [["HSET", hash, k1, v1], ["HSET", hash, k2, v2]]) == [1, 1]
    assert Redix.command(:test_pool, ["HGET", hash, k1]) == {:ok, v1}
    assert Redix.command(:test_pool, ["HGET", hash, k2]) == {:ok, v2}
  end
end
