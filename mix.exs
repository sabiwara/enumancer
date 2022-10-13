defmodule Enumancer.MixProject do
  use Mix.Project

  @version "0.0.2"
  @github_url "https://github.com/sabiwara/enumancer"

  def project do
    [
      app: :enumancer,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [
        docs: :docs,
        "hex.publish": :docs,
        dialyzer: :test
      ],
      dialyzer: [flags: [:missing_return, :extra_return]],

      # hex
      description: "Elixir macros to effortlessly define highly optimized Enum pipelines",
      package: package(),
      name: "Enumancer",
      docs: docs()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      # doc, benchs
      {:ex_doc, "~> 0.25.0", only: :docs, runtime: false},
      {:benchee, "~> 1.0", only: :bench, runtime: false},
      # CI
      {:dialyxir, "~> 1.0", only: :test, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["sabiwara"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github_url},
      files: ~w(lib mix.exs README.md LICENSE.md CHANGELOG.md)
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @github_url,
      homepage_url: @github_url,
      extras: ["README.md", "CHANGELOG.md", "LICENSE.md"]
    ]
  end
end
