defmodule IrisEx.Config do
  @moduledoc """
  Configuration helper for IrisEx.
  """
  @default_ws_url "ws://redroid:3000/ws"
  @default_http_url "http://redroid:3000"

  def extensions do
    Application.get_env(:iris_ex, :extensions, [])
  end

  def ws_url do
    Application.get_env(:iris_ex, :ws_url, @default_ws_url)
  end

  def http_url do
    Application.get_env(:iris_ex, :http_url, @default_http_url)
  end
end
