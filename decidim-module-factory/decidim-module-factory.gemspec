# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/module_factory/version"

Gem::Specification.new do |s|
  s.version = Decidim::ModuleFactory.version
  s.authors = ["Bastin"]
  s.email = ["BastinJafari@gmail.com"]
  s.license = "AGPL-3.0-or-later"
  s.homepage = "https://decidim.org"
  s.metadata = {
    "bug_tracker_uri" => "https://github.com/decidim/decidim/issues",
    "documentation_uri" => "https://docs.decidim.org/",
    "funding_uri" => "https://opencollective.com/decidim",
    "homepage_uri" => "https://decidim.org",
    "source_code_uri" => "https://github.com/decidim/decidim"
  }
  s.required_ruby_version = "~> 3.3"

  s.name = "decidim-module-factory"
  s.summary = "A generator for decidim modules with AI rules."
  s.description = "This gem provides a new generator command for decidim to create module boilerplate with AI development guidelines."

  s.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").select do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w(app/ config/ db/ lib/ exe/ LICENSE-AGPLv3.txt Rakefile README.md))
    end
  end

  s.bindir = "exe"
  s.executables = ["decidim-module-factory"]

  s.add_dependency "decidim-core", "0.31.0.dev"
  s.add_dependency "decidim-generators", "0.31.0.dev"
end
