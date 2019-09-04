:ok = Application.ensure_started(:redix_pool)
RedixPool.start_pool(:test_pool)
ExUnit.start()

