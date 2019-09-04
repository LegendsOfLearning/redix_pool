defmodule RedixPoolConfigTest do
  use ExUnit.Case, async: true

  test "config values" do
    %{
      redis_url: redis_url
    } = RedixPool.Config.config_map(pool: :test_config)

    assert redis_url == "redis://127.0.0.1/6379/5"
  end

  test "system env parsing" do
    assert System.get_env("TEST_REDIS_URL") == nil

    %{
      redis_url: redis_url
    } = RedixPool.Config.config_map(pool: :test_env_config)

    assert redis_url == "redis://127.0.0.1/6379/1"

    expected_port = 4000 + :rand.uniform(2000)
    expected_redis_url = "redis://127.0.0.1/#{expected_port}/3"
    :ok = System.put_env("TEST_REDIS_URL", expected_redis_url)

    assert System.get_env("TEST_REDIS_URL") == expected_redis_url

    %{
      redis_url: redis_url
    } = RedixPool.Config.config_map(pool: :test_env_config)
    assert redis_url == expected_redis_url
  end
end
