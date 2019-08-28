defmodule RedixPool.Mixfile do
  use Mix.Project

  @version "0.3.0"
  @description "Redis pooling built on redix and poolboy. Supports multiple pools and redix connection options."
  @github_url "https://github.com/LegendsOfLearning/redix_pool"

  def project do
    [app: :redix_pool,
     version: @version,
     description: @description,
     package: package(),
     elixir: "~> 1.6",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def package do
    [maintainers: ["Connor Jacobsen", "Ho-Sheng Hsiao"],
     homepage_url: @github_url,
     licenses: ["MIT"],
     links: %{"Github" => @github_url},
     source_url: @github_url]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     mod: {RedixPool, [[pool: :default], [pool: :test_pool]]}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
     {:secure_random, "~> 0.5", only: :dev, runtime: false},
     {:redix, "~> 0.10"},
     {:poolboy, "~> 1.5"}]
  end
end
