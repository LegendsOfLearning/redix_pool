# RedixPool

Simple Redis pooling built on [redix](https://github.com/whatyouhide/redix) and [poolboy](https://github.com/devinus/poolboy).

![circleci-shield](https://circleci.com/gh/opendoor-labs/redix_pool.svg?style=shield&circle-token=c503d1e0da6337b12043465c54ac240d0e902d04)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `redix_pool` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:redix_pool, "~> 0.1.0"}]
end
```

```elixir
def deps do
  [{:redix_pool, github: "LegendsOfLearning/redix_pool", branch: "master"}]
end
```

## Configuration

`RedixPool` currently only supports a few basic configuration options:

```elixir
# myapp/config/config.exs
use Mix.Config

config :redix_pool, :redix_default
  redis_url: "redis://localhost:6379",
  pool_size: {:system, "POOL_SIZE"}, # System.get_env("POOL_SIZE") will be executed at runtime
  pool_max_overflow: 1,
  redix_opts: [
    sync_connect: true,
  ]

# A pool named "sessions_rw"
config :redix_pool, :sessions_rw,
  redis_url: {:system, "SESSION_READ_REDIS_URL"}, # Defaults to redis://localhost:6379/0
  redix_opts: [
    timeout: 3000,
    backoff_initial: 1000,
    backoff_max: 10000,
    sock_opts: [:verify, :verify_none]
  ], # See: https://hexdocs.pm/redix/0.10.2/Redix.html#start_link/1-options
  pool_size: {:system, "SESSION_READ_POOL_SIZE", 8}
  pool_max_overflow: {:system, "SESSION_READ_MAX_OVERFLOW", 16},
  timeout: 10000
```

## Basic Usage

`RedixPool` supports `command/3` and `pipeline/3` (and their bang variants), which are just like the `Redix` `command/3` and `pipeline/3` functions, except `RedixPool` handles the connection for you.

This means using `command` is as simple as:

```elixir
alias RedixPool, as: Redis

Redis.command(:redix_default, ["FLUSHDB"])
#=> {:ok, "OK"}

Redis.command(:redix_default, ["SET", "foo", "bar"])
#=> {:ok, "OK"}

Redis.command(:redix_default, ["GET", "foo"])
#=> {:ok, "bar"}
```

## Testing

Currently, the tests assume you have an instance of Redis running locally at `localhost:6379`.

On OSX, Redis can be installed easily with `brew`:

```bash
brew install redis
```

Once you have Redis running, simply run `mix test`.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/redix_pool](https://hexdocs.pm/redix_pool).

