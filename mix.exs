defmodule Protoss.MixProject do
  use Mix.Project

  def project do
    [
      app: :protoss,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end
  
  @source_url "https://github.com/ityonemo/protoss"

  defp package do
    [
      description: "Protoss is an evil, powerful Protocol library.",
      licenses: ["MIT"],
      files: ~w[lib .formatter.exs mix.exs README.md LICENSE.md],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
       {:ex_doc, "~> 0.31", only: :dev}
    ]
  end
end
