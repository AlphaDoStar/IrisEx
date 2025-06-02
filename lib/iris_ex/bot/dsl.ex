defmodule IrisEx.Bot.DSL do
  @moduledoc """
  DSL macros for defining bot behaviours.
  """

  defmacro on(event_type, do: block) do
    quote do
      def handle_event(unquote(event_type), chat) do
        var!(chat) = chat
        var!(match_handled) = if Process.alive?(self()), do: false, else: true
        unquote(block)
        _ = var!(match_handled)
      end
    end
  end

  defmacro set(id_expr) do
    quote do
      var!(agent_id) = unquote(id_expr)
    end
  end

  defmacro state(state_name, do: block) do
    quote do
      agent_state = IrisEx.Bot.Agent.get(var!(agent_id))
      if agent_state == unquote(state_name) do
        unquote(block)
      end
    end
  end

  defmacro match(pattern, do: block) when is_binary(pattern) do
    quote do
      if not var!(match_handled) do
        message = var!(chat).message.content
        if message == unquote(pattern) do
          var!(match_handled) = true
          unquote(block)
          _ = var!(match_handled)
        end
      end
    end
  end

  defmacro match(pattern, do: block) do
    quote do
      if not var!(match_handled) do
        message = var!(chat).message.content
        case Regex.run(unquote(pattern), message, capture: :all_but_first) do
          nil -> :ok
          captured ->
            var!(match_handled) = true
            var!(args) = captured
            unquote(block)
            _ = var!(match_handled)
            _ = var!(args)
        end
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

  defmacro trans(state) do
    quote do
      IrisEx.Bot.Agent.put(var!(agent_id), unquote(state))
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def handle_event(_, _), do: :ok
    end
  end
end
