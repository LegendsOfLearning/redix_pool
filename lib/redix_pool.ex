defmodule RedixPool do
  @moduledoc """
  This module provides an API for using `Redix` through a pool of workers.

  ## Overview

  `RedixPool` is very simple, it is merely wraps `Redix` with a pool of `Poolboy`
  workers. All function calls get passed through to a `Redix` connection.

  Please see the [redix](https://github.com/whatyouhide/redix) library for
  more in-depth documentation. Many of the examples in this documentation are
  pulled directly from the `Redix` docs.
  """
  use Application

  alias RedixPool.Config

  @type command :: [binary]

  @pool_name_prefix :redix_pool
  @default_redis_url "redis://localhost:6379/0"
  @default_pool_size 4
  @default_pool_max_overflow 8

  # This is hard-coded into the poolboy calls. Because
  # we are inferring information here, we don't want to
  # be doing this after getting the pool started.
  # ways we can try to make this configurable:
  #   - Store stuff back into Application env after computing it
  #   - Use the Ecto.Repo pattern, and let the developer
  #     decide how to get this config.
  @default_timeout 5000

  def start(_type, args) do
    import Supervisor.Spec, warn: false

    pool_key = args[:pool] || :default
    default_pool_name = "#{@pool_name_prefix}_#{pool_key}" |> String.to_atom

    pool_name  = args[:pool_name]  || Config.get({pool_key, :pool_name}, default_pool_name)
    redis_url  = args[:redis_url]  || Config.get({pool_key, :redis_url}, @default_redis_url)
    # TODO: Possibly filter this through resolve_config {:system, _}
    redix_opts = args[:redix_opts] || Config.get({pool_key, :redix_opts}, [])

    pool_size= args[:pool_size] || Config.get({pool_key, :pool_size, :integer}, @default_pool_size)
    pool_max_overflow = args[:pool_max_overflow] ||
      Config.get({pool_key, :pool_size, :integer}, @default_pool_max_overflow)

    pool_options = [
      name:          {:local, pool_name},
      worker_module: RedixPool.Worker,
      size:          pool_size,
      max_overflow:  pool_max_overflow
    ]

    worker_options = [
      redis_url:  redis_url,
      redix_opts: redix_opts,
    ]

    children = [
      :poolboy.child_spec(pool_name, pool_options, worker_options)
    ]

    opts = [strategy: :one_for_one, name: RedixPool.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc"""
  Wrapper to call `Redix.command/3` inside a poolboy worker.

  ## Examples

      iex> RedixPool.command(:redix_pool_default, ["SET", "k", "foo"])
      {:ok, "OK"}
      iex> RedixPool.command(:redix_pool_default, ["GET", "k"])
      {:ok, "foo"}
  """
  @spec command(atom, command, Keyword.t) ::
        {:ok, [Redix.Protocol.redis_value]} | {:error, atom | Redix.Error.t}
  def command(pool_name, args, opts \\ []) do
    :poolboy.transaction(
      pool_name,
      fn(worker) -> GenServer.call(worker, {:command, args, opts}) end,
      @default_timeout
    )
  end

  @doc"""
  Wrapper to call `Redix.command!/3` inside a poolboy worker, raising if
  there's an error.

  ## Examples

      iex> RedixPool.command!(:radix_pool_default, ["SET", "k", "foo"])
      "OK"
      iex> RedixPool.command!(:radix_pool_default, ["GET", "k"])
      "foo"
  """
  @spec command!(atom, command, Keyword.t) :: Redix.Protocol.redis_value | no_return
  def command!(pool_name, args, opts \\ []) do
    :poolboy.transaction(
      pool_name,
      fn(worker) -> GenServer.call(worker, {:command!, args, opts}) end,
      @default_timeout
    )
  end

  @doc"""
  Wrapper to call `Redix.pipeline/3` inside a poolboy worker.

  ## Examples

      iex> RedixPool.pipeline(:radix_pool_default, [["INCR", "mykey"], ["INCR", "mykey"], ["DECR", "mykey"]])
      {:ok, [1, 2, 1]}

      iex> RedixPool.pipeline(:radix_pool_default, [["SET", "k", "foo"], ["INCR", "k"], ["GET", "k"]])
      {:ok, ["OK", %Redix.Error{message: "ERR value is not an integer or out of range"}, "foo"]}
  """
  @spec pipeline(atom, [command], Keyword.t) ::
        {:ok, [Redix.Protocol.redis_value]} | {:error, atom}
  def pipeline(pool_name, args, opts \\ []) do
    :poolboy.transaction(
      pool_name,
      fn(worker) -> GenServer.call(worker, {:pipeline, args, opts}) end,
      @default_timeout
    )
  end

  @doc"""
  Wrapper to call `Redix.pipeline!/3` inside a poolboy worker, raising if there
  are errors issuing the commands (but not if the commands are successfully
  issued and result in errors).

  ## Examples

      iex> RedixPool.pipeline!(:radix_pool_default, j[["INCR", "mykey"], ["INCR", "mykey"], ["DECR", "mykey"]])
      [1, 2, 1]

      iex> RedixPool.pipeline!(:radix_pool_default, [["SET", "k", "foo"], ["INCR", "k"], ["GET", "k"]])
      ["OK", %Redix.Error{message: "ERR value is not an integer or out of range"}, "foo"]
  """
  @spec pipeline!(atom, [command], Keyword.t) :: [Redix.Protocol.redis_value] | no_return
  def pipeline!(pool_name, args, opts \\ []) do
    :poolboy.transaction(
      pool_name,
      fn(worker) -> GenServer.call(worker, {:pipeline!, args, opts}) end,
      @default_timeout
    )
  end
end
