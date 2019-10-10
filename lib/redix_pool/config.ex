defmodule RedixPool.Config do
  @moduledoc """
  ## Example Pool Configurations

  ```
  # All pools listed in start_pools will be automatically
  # started upon application start. Pools not started here
  # can be started by adding RedixPool.redix_pool_spec(pool: pool_name)
  # into a supervision tree.
  config :redix_pool,
    start_pools: [:redix_default]

  config :redix_pool, :redix_default,
    redis_url: {:system, "DEFAULT_REDIS_URL"},
    # https://hexdocs.pm/redix/0.10.2/Redix.html#start_link/1-options
    redix_opts: [
      sync_connect: true,
      sock_opts: [:verify, :verify_none],
    ],
    pool_size: {:system, "DEFAULT_POOL_SIZE", 4}
    pool_max_overflow: {:system, "DEFAULT_MAX_OVERFLOW", 8},
    timeout: 5000

  # A pool named "read". This is also used to compute the process name
  config :redix_pool, :sessions_ro,
    redis_url: {:system, "SESSION_READ_REDIS_URL"}, # Defaults to redis://localhost:6379/0
    redix_opts: [
      timeout: 3000,
      backoff_initial: 1000,
      backoff_max: 10000,
      sock_opts: [:verify, :verify_none]
    ],
    pool_size: {:system, "SESSION_READ_POOL_SIZE", 8}
    pool_max_overflow: {:system, "SESSION_READ_MAX_OVERFLOW", 16}
  """

  @default_redis_url "redis://localhost:6379/0"
  @default_pool_size 4
  @default_pool_max_overflow 8

  @doc "Compute and parse config map by pool name"
  def config_map(args) do
    pool_name = args[:pool] || raise "Must pass [pool: pool_name]"

    # TODO: Possibly filter this through resolve_config {:system, _}
    redis_url  = args[:redis_url]  || get({pool_name, :redis_url})
    redix_opts_from_config = args[:redix_opts] || get({pool_name, :redix_opts}, [])

    # TODO: Use separate SSL socket opts when SSL is requested
    redix_opts = @default_redis_url
    |> opts_from_uri                           # Defaults
    |> Keyword.merge(redix_opts_from_config)   # Override from config
    |> Keyword.merge(opts_from_uri(redis_url)) # Override from supplied redis uri
    |> normalize_redix_opts                    # Filter out ssl socket_opts' if not using ssl

    pool_size= args[:pool_size] || get({pool_name, :pool_size, :integer}, @default_pool_size)
    pool_max_overflow = args[:pool_max_overflow] ||
      get({pool_name, :pool_max_overflow, :integer}, @default_pool_max_overflow)

    %{
      pool_name: pool_name,
      redix_opts: redix_opts,
      pool_size: pool_size,
      pool_max_overflow: pool_max_overflow
    }
  end

  @doc "Gets the list of pools to start when RedixPool application starts"
  def starting_pools, do: Application.get_env(:redix_pool, :start_pools, [])

  @doc false
  def normalize_redix_opts(opts) do
    cond do
      opts[:ssl] == true -> opts
      !is_nil(opts[:socket_opts][:verify]) ->
        # If we are not using SSL, then drop the verify option, otherwise
        # Erlang tcp will fail
        Keyword.put(opts, :socket_opts, Keyword.drop(opts[:socket_opts], [:verify]))
      true -> opts
    end
  end

  @doc false
  def get({pool_name, key, :integer}, default) do
    {pool_name, key}
    |> get(default)
    |> maybe_to_integer
  end

  @doc false
  def get({pool_name, key}, default) do
    :redix_pool
    |> Application.get_env(pool_name, %{})
    |> Access.get(key)
    |> resolve_config(default)
  end

  @doc false
  def get(key, default) when is_atom(key) do
    get({:default, key}, default)
  end

  def get({_pool_name, _key, :integer} = spec), do: get(spec, nil)
  def get({_pool_name, _key} = spec), do: get(spec, nil)

  @doc false
  def get(key) when is_atom(key), do: get(key, nil)

  @doc "Helper function useful for parsing ENV variables"
  def maybe_to_integer(x) when is_binary(x),  do: String.to_integer(x)
  def maybe_to_integer(x) when is_integer(x), do: x
  def maybe_to_integer(x) when is_nil(x),     do: nil

  @doc false
  def resolve_config({:system, var_name, user_default}, _lib_default),
    do: System.get_env(var_name) |> present_or_default(user_default)
  def resolve_config({:system, var_name}, default),
    do: System.get_env(var_name) |> present_or_default(default)
  def resolve_config(value, default) when is_nil(value), do: default
  def resolve_config(value, _default), do: value

  @doc false
  defp present_or_default(x, default) when is_nil(x), do: default
  defp present_or_default("", default), do: default
  defp present_or_default(x, _default), do: x

  @doc false
  # Add identity clauses
  defp opts_from_uri(nil), do: []
  defp opts_from_uri(""), do: []
  defp opts_from_uri(uri) when is_binary(uri), do: Redix.URI.opts_from_uri(uri)
end
