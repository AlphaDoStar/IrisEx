defmodule IrisEx.Bot.Agent do
  @moduledoc """
  State agent for bot modules.
  """
  use Agent

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    Agent.start_link(fn -> %{} end, opts)
  end

  def put(id, state) do
    Agent.update(__MODULE__, &Map.put(&1, id, state))
  end

  def get(id) do
    Agent.get(__MODULE__, &Map.get(&1, id, :default))
  end
end
