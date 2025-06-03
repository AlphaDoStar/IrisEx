defmodule IrisEx.Bot.DSL do
  @moduledoc """
  DSL macros for defining bot behaviours.
  """

  defmacro on(event_type, do: block) do
    quote do
      def handle_event(unquote(event_type), chat) do
        var!(chat) = chat
        Process.put(:agent_id, var!(chat)[:sender][:id])
        Process.put(:agent_state, IrisEx.Bot.Agent.get(Process.get(:agent_id)))
        Process.put(:matched, false)
        unquote(block)
      end
    end
  end

  defmacro set(id_expr) do
    quote do
      Process.put(:agent_id, unquote(id_expr))
      Process.put(:agent_state, IrisEx.Bot.Agent.get(Process.get(:agent_id)))
    end
  end

  defmacro state(state, do: block) do
    quote do
      if Process.get(:agent_state) == unquote(state) do
        unquote(block)
      end
    end
  end

  defmacro match(pattern, do: block) when is_binary(pattern) do
    quote do
      if not Process.get(:matched) do
        message = var!(chat)[:message][:content]
        if message == unquote(pattern) do
          Process.put(:matched, true)
          unquote(block)
        end
      end
    end
  end

  defmacro match(pattern, do: block) do
    quote do
      if not Process.get(:matched) do
        message = var!(chat)[:message][:content]
        case Regex.run(unquote(pattern), message, capture: :all_but_first) do
          nil -> :ok
          captured ->
            var!(args) = captured
            _ = var!(args)
            Process.put(:matched, true)
            unquote(block)
        end
      end
    end
  end

  defmacro trans(state) do
    quote do
      IrisEx.Bot.Agent.put(Process.get(:agent_id), unquote(state))
    end
  end

  defmacro continue do
    quote do
      Process.put(:matched, false)
    end
  end

  defmacro fallback(do: block) do
    quote do
      if not Process.get(:matched) do
        unquote(block)
      end
    end
  end

  defmacro reply(message, opts \\ []) do
    quote do
      trim = Keyword.get(unquote(opts), :trim, false)
      message = if trim, do: String.trim(unquote(message)), else: unquote(message)
      IrisEx.Client.send_text(var!(chat)[:room][:id], message)
    end
  end

  defmacro reply_image(base64) do
    quote do
      IrisEx.Client.send_image(var!(chat)[:room][:id], unquote(base64))
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def handle_event(_, _), do: :ok
    end
  end
end
