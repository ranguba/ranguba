ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
if (RUBY_VERSION <=> "3.1.0") < 0
  require "bootsnap/setup" # Speed up boot time by caching expensive operations.
end
