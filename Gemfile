# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

gem "decidim", path: "."
gem "decidim-ai", path: "."
gem "decidim-collaborative_texts", path: "."
gem "decidim-conferences", path: "."
gem "decidim-design", path: "."
gem "decidim-elections", path: "."
gem "decidim-initiatives", path: "."
gem "decidim-templates", path: "."

gem "bootsnap", "~> 1.4"

gem "puma", ">= 6.3.1"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "decidim-dev", path: "."

  gem "brakeman", "~> 7.0"
  gem "parallel_tests", "~> 4.2"
end

group :development do
  gem "letter_opener_web", "~> 2.0"
  gem "listen", "~> 3.1"
  gem "web-console", "~> 4.2"
end
