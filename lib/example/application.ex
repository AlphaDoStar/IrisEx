defmodule Example.Application do
  use IrisEx.Application,
    bots: [Example.Bot],
    ws_url: "ws://192.168.0.17:3000/ws",
    http_url: "http://192.168.0.17:3000",
    children: []
end
