defmodule RedixPool.Config do
  @moduledoc """
  ## Example Pool Configurations

  ```
  config :redix_pool, :default,
    redis_url: {:system, "DEFAULT_REDIS_URL"},
    sock_opts: [:verify, :verify_none],
    pool_size: {:system, "DEFAULT_POOL_SIZE", 4}
    pool_max_overflow: {:system, "DEFAULT_MAX_OVERFLOW", 8}

  # A pool named "read". This is also used to compute the process name
  config :redix_pool, :read,
    # Optional pool name. By default, it is :redix_pool_<pool_name>
    # pool_name: :session_read_pool,

    redis_url: {:system, "SESSION_READ_REDIS_URL"}, # Defaults to redis://localhost:6379/0
    sock_opts: [:verify, :verify_none],
    pool_size: {:system, "SESSION_READ_POOL_SIZE", 8}
    pool_max_overflow: {:system, "SESSION_READ_MAX_OVERFLOW", 16}
  """

  @doc false
  def get({pool_name, key, :integer}, default \\ nil) do
    {pool_name, key}
    |> get(default)
    |> maybe_to_integer
  end

  @doc false
  def get({pool_name, key}, default \\ nil) do
    value = Application.get_env(:redix_pool, pool_name, %{})[key] || default
    resolve_config(value)
  end

  @doc false
  def get(key, default \\ nil) when is_atom(key) do
    get({:default, key}, default)
  end

  @doc "Helper function useful for parsing ENV variables"
  def maybe_to_integer(x) when is_binary(x),  do: String.to_integer(x)
  def maybe_to_integer(x) when is_integer(x), do: x
  def maybe_to_integer(x) when is_nil(x),     do: nil

  defp either(a,b) do
    if a do
      a
    else
      b
    end
  end

  @doc false
  def resolve_config({:system, var_name}, default),
    do: System.get_env(var_name) || default
  def resolve_config(value, _default),
    do: value
end
