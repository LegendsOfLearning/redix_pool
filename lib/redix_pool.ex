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

  # This is hard-coded into the poolboy calls. Because
  # we are inferring information here, we don't want to
  # be doing this after getting the pool started.
  # ways we can try to make this configurable:
  #   - Store stuff back into Application env after computing it
  #   - Use the Ecto.Repo pattern, and let the developer
  #     decide how to get this config.
  @default_timeout 5000

  @doc "Start the default pool if args is empty"
  def start(type, args) when length(args) == 0, do: start(type, [[]])

  @doc """
  Pass a list of pool specs to start

  Example

  ```elixir
  def application do
      [mod: {RedixPool,[
        [pool: :redix_default],
        [pool: :sessions_ro, pool_name: :session_ro]]}]
  end
  ```

  ```elixir
    config :redix_pool, :redix_default, []
    config :redix_pool, :sessions_ro, []
  ```
  """
  def start(_type, _args) do
    children = Config.starting_pools
    |> Enum.map(&__MODULE__.redix_pool_spec/1)
    # |> IO.inspect

    opts = [strategy: :one_for_one, name: RedixPool.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc "Convenience helper for starting a pool supervisor"
  def start_pool(pool_name) when is_atom(pool_name), do: start_pool(pool: pool_name)
  def start_pool(args) when is_list(args) do
    children = [RedixPool.redix_pool_spec(args)]
    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
    {:ok, pid}
  end

  @doc "Returns a poolboy child spec based upon parsing configs"
  def redix_pool_spec(pool_name) when is_atom(pool_name), do: redix_pool_spec(pool: pool_name)
  def redix_pool_spec(args) when is_list(args) do
    %{
      pool_name: pool_name,
      redix_opts: redix_opts,
      pool_size: pool_size,
      pool_max_overflow: pool_max_overflow
    } = Config.config_map(args)

    pool_options = [
      name:          {:local, pool_name},
      worker_module: Redix,
      size:          pool_size,
      max_overflow:  pool_max_overflow
    ]

    :poolboy.child_spec(pool_name, pool_options, redix_opts)
  end

  @doc """
  Returns a child spec for a single worker based upon parsing configs.
  """
  def redix_worker_spec(args) do
    %{
      redix_opts: redix_opts,
    } = Config.config_map(args)

    Redix.child_spec(redix_opts)
  end

  @doc """
  Normalizes the Redix worker args so that it is compatible with poolboy.
  Extracted from the Redix source code.
  """
  def normalize_redix_spec({uri, other_opts}) do
    uri
    |> Redix.URI.opts_from_uri
    |> Keyword.merge(other_opts)
  end

  @doc"""
  Wrapper to call `Redix.command/3` inside a poolboy transaction.

  ## Examples

      iex> RedixPool.command(:redix_default, ["SET", "k", "foo"])
      {:ok, "OK"}
      iex> RedixPool.command(:redix_default, ["GET", "k"])
      {:ok, "foo"}
  """
  @spec command(atom, command, Keyword.t) ::
        {:ok, [Redix.Protocol.redis_value]} | {:error, atom | Redix.Error.t}
  def command(pool_name, args, opts \\ []) do
    :poolboy.transaction(
      pool_name,
      fn(conn) -> Redix.command(conn, args, opts) end,
      poolboy_timeout(pool_name)
    )
  end

  @doc"""
  Wrapper to call `Redix.command!/3` inside a poolboy transaction, raising if
  there's an error.

  ## Examples

      iex> RedixPool.command!(:redix_default, ["SET", "k", "foo"])
      "OK"
      iex> RedixPool.command!(:redix_default, ["GET", "k"])
      "foo"
  """
  @spec command!(atom, command, Keyword.t) :: Redix.Protocol.redis_value | no_return
  def command!(pool_name, args, opts \\ []) do
    :poolboy.transaction(
      pool_name,
      fn(conn) -> Redix.command!(conn, args, opts) end,
      poolboy_timeout(pool_name)
    )
  end

  @doc"""
  Wrapper to call `Redix.pipeline/3` inside a poolboy transaction.

  ## Examples

      iex> RedixPool.pipeline(:redix_default, [["INCR", "mykey"], ["INCR", "mykey"], ["DECR", "mykey"]])
      {:ok, [1, 2, 1]}

      iex> RedixPool.pipeline(:redix_default, [["SET", "k", "foo"], ["INCR", "k"], ["GET", "k"]])
      {:ok, ["OK", %Redix.Error{message: "ERR value is not an integer or out of range"}, "foo"]}
  """
  @spec pipeline(atom, [command], Keyword.t) ::
        {:ok, [Redix.Protocol.redis_value]} | {:error, atom}
  def pipeline(pool_name, args, opts \\ []) do
    :poolboy.transaction(
      pool_name,
      fn(conn) -> Redix.pipeline(conn, args, opts) end,
      poolboy_timeout(pool_name)
    )
  end

  @doc"""
  Wrapper to call `Redix.pipeline!/3` inside a poolboy transaction, raising if there
  are errors issuing the commands (but not if the commands are successfully
  issued and result in errors).

  ## Examples

      iex> RedixPool.pipeline!(:redix_default, [["INCR", "mykey"], ["INCR", "mykey"], ["DECR", "mykey"]])
      [1, 2, 1]

      iex> RedixPool.pipeline!(:redix_default, [["SET", "k", "foo"], ["INCR", "k"], ["GET", "k"]])
      ["OK", %Redix.Error{message: "ERR value is not an integer or out of range"}, "foo"]
  """
  @spec pipeline!(atom, [command], Keyword.t) :: [Redix.Protocol.redis_value] | no_return
  def pipeline!(pool_name, args, opts \\ []) do
    :poolboy.transaction(
      pool_name,
      fn(conn) -> Redix.pipeline!(conn, args, opts) end,
      poolboy_timeout(pool_name)
    )
  end

  @doc false
  defp poolboy_timeout(pool_name) do
    :radix_pool
    Application.get_env(:radix_pool, pool_name)
    |> Access.get(:timeout, @default_timeout)
  end
end
