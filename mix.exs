defmodule IrisEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :iris_ex,
      version: "0.3.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {IrisEx.Application, []}
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 2.2.3"},
      {:websockex, "~> 0.4.3"}
    ]
  end
end
