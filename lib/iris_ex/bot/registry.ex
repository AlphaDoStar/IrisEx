defmodule IrisEx.Bot.Registry do
  @moduledoc """
  Registry for bot modules.
  """
  use GenServer

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, [], opts)
  end

  def ensure_started do
    case Process.whereis(__MODULE__) do
      nil -> start_link()
      pid -> {:ok, pid}
    end
  end

  def register(module) do
    GenServer.call(__MODULE__, {:register, module})
  end

  def get_bots do
    GenServer.call(__MODULE__, :get_bots)
  end

  @impl true
  def init(_) do
    {:ok, []}
  end

  @impl true
  def handle_call({:register, module}, _from, bots) do
    if module in bots do
      {:reply, :already_registered, bots}
    else
      {:reply, :ok, [module | bots]}
    end
  end

  @impl true
  def handle_call(:get_bots, _from, bots) do
    {:reply, bots, bots}
  end
end
