defmodule DoctestsTest do
  # Doctests must run with a clean db and asynchronously
  use ExUnit.Case

  setup do
    :ok = Application.ensure_started(:redix_pool)
    RedixPool.command(:redix_default, ["FLUSHDB"])
    :ok
  end

  doctest RedixPool
end

