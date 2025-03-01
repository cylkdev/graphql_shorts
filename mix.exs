defmodule GraphQLShorts.MixProject do
  use Mix.Project

  @source_url "https://github.com/cylkdev/graphql_shorts"
  @version "0.1.0"

  def project do
    [
      app: :graphql_shorts,
      description: "GraphQL error message handling API",
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        doctor: :test,
        coverage: :test,
        dialyzer: :test,
        coveralls: :test,
        "coveralls.lcov": :test,
        "coveralls.json": :test,
        "coveralls.html": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test
      ],
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix],
        plt_ignore_apps: [],
        plt_local_path: "dialyzer",
        plt_core_path: "dialyzer",
        list_unused_filters: true,
        ignore_warnings: ".dialyzer-ignore.exs",
        flags: [:unmatched_returns, :no_improper_lists]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Static Analysis & Code Quality
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false, optional: true},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false, optional: true},
      {:blitz_credo_checks, "~> 0.1", only: [:dev, :test], runtime: false, optional: true},

      # Documentation Tools
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false, optional: true},
      {:doctor, "~> 0.1", only: [:dev, :test], runtime: false, optional: true},

      # Testing & Coverage
      {:excoveralls, "~> 0.1", only: :test, runtime: false, optional: true},
      {:ex_check, "~> 0.1", only: [:dev, :test], runtime: false, optional: true},

      # General
      {:matchbox, git: "https://github.com/cylkdev/matchbox.git", branch: "main"},
      {:proper_case, "~> 1.0"},
      {:jason, "~> 1.0", optional: true},
      {:absinthe, "~> 1.0", optional: true},
      {:ecto, "~> 3.0", optional: true},

      {:error_message, "~> 0.3", optional: true}
    ]
  end

  defp package do
    [
      maintainers: ["Kurt Hogarth"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/cylkdev/graphql_shorts"},
      files: ~w(mix.exs README.md CHANGELOG.md lib)
    ]
  end

  defp docs do
    [
      main: "GraphQLShorts",
      source_url: "https://github.com/cylkdev/graphql_shorts",
      source_url: @source_url,
      source_ref: @version,
      api_reference: false,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_docs: [
        group_for_function("Comparison Engine API")
      ],
      groups_for_modules: [
        "ComparisonEngine API": [
          GraphQLShorts.ComparisonEngine,
          GraphQLShorts.CommonComparison
        ]
      ]
    ]
  end

  defp extras do
    [
      # "guides/howtos/example.md",
      "CHANGELOG.md": [],
      "LICENSE.txt": [title: "License"],
      "README.md": [title: "Readme"]
    ]
  end

  defp group_for_function(group), do: {String.to_atom(group), &(&1[:group] == group)}

  defp groups_for_extras do
    [
      "How-To's": ~r/guides\/howtos\/.?/
    ]
  end
end
