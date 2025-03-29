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
        v = case get_in(parsed, ["json", "v"]) |> JSON.decode() do
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
            type: get_in(parsed, ["json", "type"]),
            content: get_in(parsed, ["json", "message"]),
            attachment: get_in(parsed, ["json", "attachment"]),
            v: v
          },
          raw: parsed["json"]
        }

        extended_chat = extend_chat(chat)
        IO.inspect(chat, pretty: true)

        IrisEx.Bot.Registry.get_bots()
        |> Enum.each(fn bot ->
          Task.Supervisor.start_child(
            IrisEx.TaskSupervisor,
            fn -> get_event_type(v) |> bot.handle_event(extended_chat) end
          )
        end)

      {:error, error} ->
        Logger.error("Failed to parse WebSocket message: #{inspect(error)}")
    end

    {:ok, state}
  end
  def handle_frame({:binary, _message}, state), do: {:ok, state}
  def handle_frame(_frame, state), do: {:ok, state}

  def handle_disconnect(%{reason: reason}, state) do
    Logger.info("WebSocket disconnected: #{inspect(reason)}")
    {:ok, state}
  end

  def send_text(room_id, message) do
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

  def query(query_str, bind) do
    http_endpoint = "#{IrisEx.Config.http_url()}/query"
    payload = JSON.encode!(%{query: query_str, bind: bind})
    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.post(http_endpoint, payload, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        JSON.decode!(body)["body"]
      {:ok, response} ->
        Logger.info("Failed to run query: #{inspect(response.body)}")
      {:error, error} ->
        Logger.error("Failed to send query: #{inspect(error)}")
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

  defp extend_chat(chat) do
    IO.inspect(IrisEx.Config.extensions, pretty: true)

    IrisEx.Config.extensions()
    |> Enum.reduce(chat, fn extension, extended_chat ->
      case extension do
        :room_type ->
          extend_with_room_type(extended_chat)
        _ ->
          extended_chat
      end
    end)
  end

  defp extend_with_room_type(chat) do
    query_str = "SELECT type FROM chat_rooms where id = ?"
    room_id = get_in(chat, [:room, :id])

    type =
      IrisEx.Client.query(query_str, [room_id])["data"]
      |> List.first(%{})
      |> Map.get("type", "Unknown")

    chat |> put_in([:room, :type], type)
  end
end
