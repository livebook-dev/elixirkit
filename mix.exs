defmodule ElixirKit.MixProject do
  use Mix.Project

  @version "0.1.0-dev"
  @source_url "https://github.com/livebook-dev/elixirkit"

  def project do
    [
      app: :elixirkit,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package(),
      docs: docs()
    ]
  end

  def cli do
    [preferred_envs: ["test.all": :test]]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      description: "Run Elixir from Rust/Tauri apps and exchange messages over PubSub.",
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "https://hexdocs.pm/req/changelog.html"
      },
      files: [
        "lib",
        ".formatter.exs",
        "mix.exs",
        "README.md",
        "LICENSE*",
        "license*",
        "CHANGELOG.md",
        "elixirkit_rs/Cargo.toml",
        "elixirkit_rs/src"
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "guides/tauri.md"]
    ]
  end

  defp aliases do
    [
      docs: [&docs/1, "docs.rs"],
      "docs.rs": &docs_rs/1,
      "test.all": &test_all/1,
      "test.rs": [
        "cmd cargo check --manifest-path elixirkit_rs/Cargo.toml",
        "cmd cargo test --manifest-path elixirkit_rs/Cargo.toml"
      ],
      "test.examples": [
        "cmd ./examples/cli_script.rs"
      ]
    ]
  end

  defp test_all(args) do
    Mix.Task.run("test", args)
    Mix.Task.run("test.rs")
    Mix.Task.run("test.examples")
    validate_versions()
  end

  defp validate_versions do
    {output, 0} =
      System.cmd("cargo", ["pkgid", "--manifest-path", "#{__DIR__}/elixirkit_rs/Cargo.toml"])

    cargo_version = output |> String.trim() |> String.split("@") |> List.last()

    if cargo_version != @version do
      Mix.raise("""
      version mismatch:

      mix.exs:    #{@version}
      Cargo.toml: #{cargo_version}
      """)
    end
  end

  defp docs(_) do
    readme = File.read!("README.md")
    File.write!("README.md", String.replace(readme, "https://hexdocs.pm/elixirkit/", ""))

    Mix.Task.run("compile")

    try do
      Mix.Task.run("docs")
    after
      File.write!("README.md", readme)
    end
  end

  defp docs_rs(_) do
    case Mix.shell().cmd("cargo doc --no-deps --manifest-path elixirkit_rs/Cargo.toml") do
      0 ->
        File.rm_rf!("doc/rs")
        File.cp_r!("elixirkit_rs/target/doc", "doc/rs")

      status ->
        Mix.raise("cargo doc failed with exit code #{status}")
    end
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, warn_if_outdated: true},
      {:makeup_syntect, ">= 0.0.0", only: :dev}
    ]
  end
end
