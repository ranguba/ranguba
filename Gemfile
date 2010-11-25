# -*- ruby -*-

source 'http://rubygems.org'

gem 'rails', '3.0.1'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'glib2'
gem 'nokogiri'
gem 'chuparuby'

gem 'rroonga'
gem 'racknga'
if ENV["RAILS_ENV"] == "production"
  gem 'activegroonga'
else
  active_groonga_path = Pathname.new(__FILE__).dirname.parent + "activegroonga"
  unless active_groonga_path.exist?
    system("git", "clone",
           "git://github.com/ranguba/activegroonga.git",
           active_groonga_path.to_s)
  end
  unless (active_groonga_path + "activegroonga-1.0.0.gemspec").exist?
    Dir.chdir(active_groonga_path) do
      ruby = File.join(RbConfig::CONFIG["bindir"],
                       RbConfig::CONFIG["RUBY_INSTALL_NAME"])
      system(ruby, "-S", "rake", "-s", "generate_gemspec")
    end
  end
  gem 'activegroonga', :path => active_groonga_path
end

gem 'will_paginate', '>=3.0.pre'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'test-unit'
  gem 'test-unit-notify', '>= 0.1.0'
  gem 'capybara'
  gem 'launchy'
  gem 'hoe'
  gem 'rake-compiler'
end
