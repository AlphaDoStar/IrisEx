defmodule IrisEx.Bot do
  @moduledoc """
  Define behaviour and provide API for working with bots.
  """
  @type event_type :: atom()
  @type chat :: %{room: room(), sender: sender(), message: message(), raw: map()}
  @type room :: %{id: String.t(), name: String.t()}
  @type sender :: %{id: String.t(), name: String.t()}
  @type message :: %{id: String.t(), type: String.t(), content: String.t(), attachment: map(), v: map()}
  @callback handle_event(event_type(), chat()) :: term()

  def init, do: IrisEx.Bot.Registry.ensure_started()
  def register(module), do: IrisEx.Bot.Registry.register(module)

  defmacro __using__(_opts) do
    quote do
      @behaviour IrisEx.Bot
      import IrisEx.Bot.DSL

      @before_compile IrisEx.Bot.DSL
    end
  end
end
