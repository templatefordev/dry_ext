defmodule DryExt.MixProject do
  use Mix.Project

  def project do
    [
      app: :dry_ext,
      version: "0.2.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:event_bus, "~> 1.6.1"},
      {:ecto_sql, "~> 3.4"}
    ]
  end
end
