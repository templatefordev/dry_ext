defmodule DryExt.MixProject do
  @moduledoc false

  use Mix.Project

  @version "0.3.1"

  def project do
    [
      app: :dry_ext,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
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
      {:ecto_sql, "~> 3.4"},
      {:plug_cowboy, "~> 2.0"},

      # Dev and test deps
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      lint: ["format --check-formatted", "credo --strict"]
    ]
  end
end
