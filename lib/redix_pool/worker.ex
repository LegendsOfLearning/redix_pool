defmodule RedixPool.Worker do
  use GenServer

  ## Client API

    def start_link(args) do
    redis_url  = args[:redis_url] || raise ":redis_url is required to start redix worker"
    redix_opts = args[:redix_opts] || []

    {:ok, conn} = Redix.start_link(redis_url, redix_opts)
    GenServer.start_link(__MODULE__, %{conn: conn}, [])
  end

  ## Server API

  def init(state) do
    {:ok, state}
  end

  @doc false
  def handle_call({command, args, opts}, _from, %{conn: conn}) do
    {:reply, apply(Redix, command, [conn, args, opts]), %{conn: conn}}
  end

end
