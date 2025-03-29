defmodule IrisEx.Bot.DSL do
  @moduledoc """
  DSL macros for defining bot behaviours.
  """

  defmacro on(event_type, do: block) do
    quote do
      def handle_event(unquote(event_type), chat) do
        var!(chat) = chat
        unquote(block)
      end
    end
  end

  defmacro match(pattern, do: block) when is_binary(pattern) do
    quote do
      message = var!(chat).message.content
      if message == unquote(pattern) do
        unquote(block)
      end
    end
  end

  defmacro match(pattern, do: block) do
    quote do
      message = var!(chat).message.content
      case Regex.run(unquote(pattern), message, capture: :all_but_first) do
        nil -> :ok
        captured ->
          var!(args) = captured
          unquote(block)
      end
    end
  end

  defmacro reply(message) do
    quote do
      IrisEx.Client.send_text(var!(chat).room.id, unquote(message) |> String.trim())
    end
  end

  defmacro reply_image(base64) do
    quote do
      IrisEx.Client.send_image(var!(chat).room.id, unquote(base64))
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def handle_event(_, _), do: :ok
    end
  end
end
