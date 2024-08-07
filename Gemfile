# -*- ruby -*-

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.0.0"
# Use Puma as the app server
gem "puma", "~> 5.0"
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# gem "turbolinks", "~> 5"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.7"
# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"
# Use Active Model has_secure_password
# gem "bcrypt", "~> 3.1.7"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.4", require: false

group :development, :test do
  # Call "byebug" anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling "console" anywhere in the code.
  gem "web-console"
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "rack-mini-profiler", "~> 2.0"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem "spring"
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara"
  gem "selenium-webdriver"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]


gem "nokogiri"
gem "chupa-text"
gem "chupa-text-decomposer-pdf"
gem "chupa-text-decomposer-libreoffice"
gem "chupa-text-decomposer-html"

base_dir = File.join(__dir__, "..")
local_groonga_client = File.join(base_dir, "groonga-client")
if File.exist?(local_groonga_client)
  gem "groonga-client", :path => local_groonga_client
else
  gem "groonga-client"
end
local_groonga_client_model = File.join(base_dir, "groonga-client-model")
if File.exist?(local_groonga_client_model)
  gem "groonga-client-model", :path => local_groonga_client_model
else
  gem "groonga-client-model"
end

gem "importmap-rails", "~> 2.0"

gem "kaminari-core"
gem "kaminari-actionview"

gem "sprockets-rails", :require => "sprockets/railtie"

group :development, :test do
  gem "test-unit"
  gem "test-unit-rails"
  gem "test-unit-capybara"
  gem "factory_bot_rails"
  gem "rails-controller-testing"
end
