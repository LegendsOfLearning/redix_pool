# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

config :redix_pool,
  start_pools: [:redix_default]

config :redix_pool, :redix_default, []

# Test a config that does not use SSL, and yet we pass in a
# verify_none. The RedixPool.Config should scrub that out.
config :redix_pool, :test_pool,
  redix_opts: [socket_opts: [verify: :verify_none]],
  timeout: 2000

config :redix_pool, :test_config,
  redis_url: "redis://127.0.0.1/6379/5"

config :redix_pool, :test_env_config,
  redis_url: {:system, "TEST_REDIS_URL", "redis://127.0.0.1/6379/1"}

# You can configure for your application as:
#
#     config :redix_pool, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:redix_pool, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
