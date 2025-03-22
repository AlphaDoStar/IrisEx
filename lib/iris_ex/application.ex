defmodule IrisEx.Application do
  @moduledoc """
  Application module for IrisEx.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: IrisEx.TaskSupervisor},
      IrisEx.Bot.Registry,
      IrisEx.Client
    ]

    opts = [strategy: :one_for_one, name: IrisEx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defmacro __using__(opts) do
    bot_modules = Keyword.get(opts, :bots, [])
    ws_url = Keyword.get(opts, :ws_url, "")
    http_url = Keyword.get(opts, :http_url, "")
    children = Keyword.get(opts, :children, [])
    strategy = Keyword.get(opts, :strategy, :one_for_one)

    quote do
      use Application

      @impl true
      def start(_type, _args) do
        Application.put_env(:iris_ex, :ws_url, unquote(ws_url))
        Application.put_env(:iris_ex, :http_url, unquote(http_url))

        {:ok, _} = Application.ensure_all_started(:iris_ex)

        unquote(bot_modules)
        |> Enum.each(&IrisEx.Bot.register/1)

        children = case unquote(children) do
          [] -> []

          {module, function} ->
            apply(module, function, [])

          function when is_function(function, 0) ->
            function.()
        end

        opts = [strategy: unquote(strategy), name: __MODULE__.Supervisor]
        Supervisor.start_link(children, opts)
      end
    end
  end
end
