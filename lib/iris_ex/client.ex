defmodule IrisEx.Client do
  @moduledoc """
  Websocket client and HTTP client for IrisEx.
  """
  use WebSockex
  require Logger

  def start_link(opts \\ []) do
    url = Keyword.get(opts, :ws_url, IrisEx.Config.ws_url())
    WebSockex.start_link(url, __MODULE__, %{}, name: __MODULE__)
  end

  def handle_connect(_conn, state) do
    Logger.info("WebSocket connected")
    {:ok, state}
  end

  def handle_frame({:text, message}, state) do
    case JSON.decode(message) do
      {:ok, parsed} ->
        v = case JSON.decode(parsed["v"]) do
          {:ok, parsed_v} -> parsed_v
          {:error, _reason} -> %{}
        end

        chat = %{
          room: %{
            id: get_in(parsed, ["json", "chat_id"]),
            name: parsed["room"]
          },
          sender: %{
            id: get_in(parsed, ["json", "user_id"]),
            name: parsed["sender"]
          },
          message: %{
            id: get_in(parsed, ["json", "id"]),
            type: get_in(parsed, ["json", "id"]),
            content: get_in(parsed, ["json", "id"]),
            attachment: get_in(parsed, ["json", "id"]),
            v: v
          },
          raw: parsed["json"]
        }

        IrisEx.Bot.Registry.get_bots()
        |> Enum.each(fn bot ->
          Task.Supervisor.start_child(
            IrisEx.TaskSupervisor,
            fn -> get_event_type(v) |> bot.handle_event(chat) end
          )
        end)

      {:error, error} ->
        Logger.error("Failed to parse WebSocket message: #{inspect(error)}")
    end

    {:ok, state}
  end

  def handle_disconnect(%{reason: reason}, state) do
    Logger.info("WebSocket disconnected: #{inspect(reason)}")
    {:ok, state}
  end

  def send_reply(room_id, message) do
    http_endpoint = "#{IrisEx.Config.http_url()}/reply"

    payload = JSON.encode!(%{
      type: "text",
      room: room_id,
      data: message
    })

    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.post(http_endpoint, payload, headers) do
      {:ok, response} ->
        Logger.info("Sent reply successfully: #{inspect(response.status_code)}")
      {:error, error} ->
        Logger.error("Failed to send reply: #{inspect(error)}")
    end
  end

  def send_image(room_id, image_base64) do
    http_endpoint = "#{IrisEx.Config.http_url()}/reply"

    payload = JSON.encode!(%{
      type: "image",
      room: room_id,
      data: image_base64
    })

    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.post(http_endpoint, payload, headers) do
      {:ok, response} ->
        Logger.info("Sent image successfully: #{inspect(response.status_code)}")
      {:error, error} ->
        Logger.error("Failed to send image: #{inspect(error)}")
    end
  end

  defp get_event_type(%{"origin" => origin}) do
    case origin do
      "MSG" -> :message
      "NEWMEM" -> :new_member
      "DELMEM" -> :del_member
      _ -> :unknown
    end
  end
  defp get_event_type(_), do: :unknown
end
