defmodule RedixPool.Worker do
  use GenServer

  alias RedixPool.Config

  ## Client API

  def start_link([redis_url: redis_url] = args) do
    redix_opts = args[:redix_opts] || []
    conn = connect(redis_url, redix_opts)
    GenServer.start_link(__MODULE__, %{conn: conn}, [])
  end

  ## Server API

  def init(state) do
    {:ok, state}
  end

  @doc false
  def handle_call({command, args, opts}, _from, %{conn: nil}) do
    conn = connect()
    {:reply, apply(Redix, command, [conn, args, opts]), %{conn: conn}}
  end

  @doc false
  def handle_call({command, args, opts}, _from, %{conn: conn}) do
    {:reply, apply(Redix, command, [conn, args, opts]), %{conn: conn}}
  end

  def connect(redis_url, opts) do
    {:ok, conn} = Redix.start_link(redis_url, opts)
    conn
  end
end
