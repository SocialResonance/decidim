# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "decidim/core/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "decidim-core"
  s.version = Decidim::Core.version
  s.authors = ["Josep Jaume Rey Peroy", "Marc Riera Casals", "Oriol Gual Oliva"]
  s.email = ["josepjaume@gmail.com", "mrc2407@gmail.com", "oriolgual@gmail.com"]
  s.homepage = "https://decidim.org"
  s.metadata = {
    "bug_tracker_uri" => "https://github.com/decidim/decidim/issues",
    "documentation_uri" => "https://docs.decidim.org/",
    "funding_uri" => "https://opencollective.com/decidim",
    "homepage_uri" => "https://decidim.org",
    "source_code_uri" => "https://github.com/decidim/decidim"
  }
  s.summary = "The core of the Decidim framework."
  s.description = "Adds core features so other engines can hook into the framework."
  s.license = "AGPL-3.0-or-later"
  s.required_ruby_version = "~> 3.3.0"

  s.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").select do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w(app/ config/ db/ lib/ Rakefile README.md))
    end
  end

  # Lock Temporarily as it is failing in 0.29 branch. More info: https://github.com/rails/rails/pull/54264
  s.add_dependency "concurrent-ruby", "= 1.3.4"

  s.add_dependency "active_link_to", "~> 1.0"
  s.add_dependency "acts_as_list", "~> 1.0"
  s.add_dependency "batch-loader", "~> 2.0"
  s.add_dependency "browser", "~> 6.2.0"
  s.add_dependency "cells-erb", "~> 0.1.0"
  s.add_dependency "cells-rails", "~> 0.1.3"
  s.add_dependency "charlock_holmes", "~> 0.7"
  s.add_dependency "chartkick", "~> 5.1.2"
  s.add_dependency "date_validator", "~> 0.12.0"
  s.add_dependency "devise", "~> 4.7"
  s.add_dependency "devise-i18n", "~> 1.2"
  s.add_dependency "diffy", "~> 3.3"
  s.add_dependency "doorkeeper", "~> 5.6", ">= 5.6.6"
  s.add_dependency "doorkeeper-i18n", "~> 4.0"
  s.add_dependency "file_validators", "~> 3.0"
  s.add_dependency "fog-local", "~> 0.6"
  s.add_dependency "geocoder", "~> 1.8"
  s.add_dependency "hashdiff", ">= 0.4.0", "< 2.0.0"
  s.add_dependency "hexapdf", "~> 1.1.0"
  s.add_dependency "image_processing", "~> 1.2"
  s.add_dependency "invisible_captcha", "~> 0.12"
  s.add_dependency "kaminari", "~> 1.2", ">= 1.2.1"
  s.add_dependency "loofah", "~> 2.19", ">= 2.19.1"
  s.add_dependency "mime-types", ">= 1.16", "< 4.0"
  s.add_dependency "mini_magick", "~> 4.9"
  s.add_dependency "net-smtp", "~> 0.5.0"
  s.add_dependency "nokogiri", "~> 1.16", ">= 1.16.2"
  s.add_dependency "omniauth", "~> 2.0"
  s.add_dependency "omniauth-facebook", "~> 5.0"
  s.add_dependency "omniauth-google-oauth2", "~> 1.0"
  s.add_dependency "omniauth-rails_csrf_protection", "~> 1.0"
  s.add_dependency "omniauth-twitter", "~> 1.4"
  s.add_dependency "paper_trail", "~> 16.0"
  s.add_dependency "paranoia", "~> 3.0.0"
  s.add_dependency "pg", "~> 1.5.0", "< 2"
  s.add_dependency "pg_search", "~> 2.2"
  s.add_dependency "premailer-rails", "~> 1.10"
  s.add_dependency "rack", "~> 2.2", ">= 2.2.8.1"
  s.add_dependency "rack-attack", "~> 6.0"
  s.add_dependency "rails", "~> 7.0.8"
  s.add_dependency "rails-i18n", "~> 7.0"
  s.add_dependency "ransack", "~> 4.2.0"
  s.add_dependency "redis", "~> 4.1"
  s.add_dependency "request_store", "~> 1.7.0"
  s.add_dependency "rqrcode", "~> 2.2.0"
  s.add_dependency "rubyXL", "~> 3.4"
  s.add_dependency "rubyzip", "~> 2.0"
  s.add_dependency "shakapacker", "~> 7.1.0"
  s.add_dependency "valid_email2", "~> 7.0"
  s.add_dependency "web-push", "~> 3.0"
  s.add_dependency "wisper", "~> 3.0"

  s.add_development_dependency "decidim-api", Decidim::Core.version
  s.add_development_dependency "decidim-dev", Decidim::Core.version
end
