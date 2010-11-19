# -*- ruby -*-

source 'http://rubygems.org'

gem 'rails', '3.0.1'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'glib2'
gem 'nokogiri'
gem 'chuparuby'

if ENV["RAILS_ENV"] == "production"
  gem 'rroonga'
  gem 'racknga'
  gem 'activegroonga'
else
  rroonga_path = Pathname.new(__FILE__).dirname.parent + "rroonga"
  unless rroonga_path.exist?
    system("git", "clone",
           "git://github.com/ranguba/rroonga.git",
           rroonga_path.to_s)
  end
  Dir.chdir(rroonga_path) do
    ruby = File.join(RbConfig::CONFIG["bindir"],
                     RbConfig::CONFIG["RUBY_INSTALL_NAME"])
    rake = $0
    system(ruby, rake, "-s", "generate_gemspec")
  end
  gem 'rroonga', :path => rroonga_path
  gem 'racknga'
  active_groonga_path = Pathname.new(__FILE__).dirname.parent + "activegroonga"
  unless active_groonga_path.exist?
    system("git", "clone",
           "git://github.com/ranguba/activegroonga.git",
           active_groonga_path.to_s)
  end
  Dir.chdir(active_groonga_path) do
    ruby = File.join(RbConfig::CONFIG["bindir"],
                     RbConfig::CONFIG["RUBY_INSTALL_NAME"])
    rake = $0
    system(ruby, rake, "-s", "generate_gemspec")
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
  gem 'test-unit', '>=2'
  gem 'test-unit-notify'
  gem 'capybara'
  gem 'launchy'
  gem 'hoe'
  gem 'rake-compiler'
end
