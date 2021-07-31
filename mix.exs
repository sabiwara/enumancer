defmodule Enumancer.MixProject do
  use Mix.Project

  def project do
    [
      app: :enumancer,
      version: "0.0.1",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [
        docs: :docs,
        "hex.publish": :docs,
        dialyzer: :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # doc, benchs
      {:ex_doc, "~> 0.25.0", only: :docs, runtime: false},
      {:benchee, "~> 1.0", only: :bench, runtime: false},
      # CI
      {:dialyxir, "~> 1.0", only: :test, runtime: false}
    ]
  end
end
