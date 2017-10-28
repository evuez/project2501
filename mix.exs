defmodule Project2501.Mixfile do
  use Mix.Project

  def project do
    [app: :project2501,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package(),
     description: "An Elixir client for Firefox's Marionette.",
     source_url: "https://github.com/evuez/project2501",
     homepage_url: "https://github.com/evuez/project2501"]
  end

  def application do
    [extra_applications: [:logger],
     mod: {Project2501.Application, []}]
  end

  defp deps do
    [{:poison, "~> 3.1"},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp package do
    [licenses: ["MIT"],
     maintainers: ["evuez <helloevuez@gmail.com>"],
     links: %{"GitHub" => "https://github.com/evuez/project2501"}]
  end
end
