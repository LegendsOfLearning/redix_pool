defmodule RedixPoolConfigTest do
  use ExUnit.Case, async: true

  test "config values redis_url" do
    %{
      redix_opts: redix_opts
    } = RedixPool.Config.config_map(pool: :test_config)

    assert redix_opts[:host] == "127.0.0.1"
    assert redix_opts[:port] == 6379
    assert redix_opts[:database] == 5
    assert redix_opts[:ssl] != true
  end

  test "system env parsing redis_url (string)" do
    assert System.get_env("TEST_REDIS_URL") == nil

    %{
      redix_opts: redix_opts
    } = RedixPool.Config.config_map(pool: :test_env_config)

    #assert redis_url == "redis://127.0.0.1:6379/1"
    assert redix_opts[:host] == "127.0.0.1"
    assert redix_opts[:port] == 6379
    assert redix_opts[:database] == 1
    assert redix_opts[:ssl] != true

    expected_port = 4000 + :rand.uniform(2000)
    expected_redis_url = "redis://127.0.0.1:#{expected_port}/3"
    :ok = System.put_env("TEST_REDIS_URL", expected_redis_url)

    assert System.get_env("TEST_REDIS_URL") == expected_redis_url

    %{
      redix_opts: redix_opts
    } = RedixPool.Config.config_map(pool: :test_env_config)
    assert redix_opts[:host] == "127.0.0.1"
    assert redix_opts[:port] == expected_port
    assert redix_opts[:database] == 3
    assert redix_opts[:ssl] != true
    # Configured ssl verify option should be removed if redis_url does not use ssl
    # TODO: We probably should make a ssl_redix_opts for just that
    assert redix_opts[:socket_opts][:verify] == nil

    expected_port = 4000 + :rand.uniform(2000)
    expected_redis_url = "rediss://127.0.0.1:#{expected_port}/3"
    :ok = System.put_env("TEST_REDIS_URL", expected_redis_url)

    assert System.get_env("TEST_REDIS_URL") == expected_redis_url

    %{
      redix_opts: redix_opts
    } = RedixPool.Config.config_map(pool: :test_env_config)
    assert redix_opts[:host] == "127.0.0.1"
    assert redix_opts[:port] == expected_port
    assert redix_opts[:database] == 3
    assert redix_opts[:ssl] == true
    assert redix_opts[:socket_opts][:verify] == :verify_none
  end

  test "system env parsing pool_size (integer)" do
    expected_default = 8
    assert System.get_env("TEST_POOL_SIZE") == nil

    %{
      pool_size: pool_size
    } = RedixPool.Config.config_map(pool: :test_env_parsing)

    assert pool_size == expected_default

    # Test parsing from env variable
    expected_pool_size = 10 + :rand.uniform(100)
    expected_pool_size_s = Integer.to_string(expected_pool_size)
    :ok = System.put_env("TEST_POOL_SIZE", expected_pool_size_s)

    assert System.get_env("TEST_POOL_SIZE") == expected_pool_size_s

    %{
      pool_size: pool_size
    } = RedixPool.Config.config_map(pool: :test_env_parsing)
    assert pool_size == expected_pool_size

    # Test parsing from env variable when it is blank
    # Should default to what has been set
    :ok = System.put_env("TEST_POOL_SIZE", "")
    assert System.get_env("TEST_POOL_SIZE") == ""

    %{
      pool_size: pool_size
    } = RedixPool.Config.config_map(pool: :test_env_parsing)
    assert pool_size == expected_default
  end

  test "system env parsing pool_max_overflow (integer)" do
    expected_default = 16
    assert System.get_env("TEST_POOL_MAX_OVERFLOW") == nil

    %{
      pool_max_overflow: pool_max_overflow
    } = RedixPool.Config.config_map(pool: :test_env_parsing)

    assert pool_max_overflow == expected_default

    # Test parsing from env variable
    expected_pool_max_overflow = 20 + :rand.uniform(100)
    expected_pool_max_overflow_s = Integer.to_string(expected_pool_max_overflow)
    :ok = System.put_env("TEST_POOL_MAX_OVERFLOW", expected_pool_max_overflow_s)

    assert System.get_env("TEST_POOL_MAX_OVERFLOW") == expected_pool_max_overflow_s

    %{
      pool_max_overflow: pool_max_overflow
    } = RedixPool.Config.config_map(pool: :test_env_parsing)
    assert pool_max_overflow == expected_pool_max_overflow

    # Test parsing from env variable when it is blank
    # Should default to what has been set
    :ok = System.put_env("TEST_POOL_MAX_OVERFLOW", "")
    assert System.get_env("TEST_POOL_MAX_OVERFLOW") == ""

    %{
      pool_max_overflow: pool_max_overflow
    } = RedixPool.Config.config_map(pool: :test_env_parsing)
    assert pool_max_overflow == expected_default
  end
end
