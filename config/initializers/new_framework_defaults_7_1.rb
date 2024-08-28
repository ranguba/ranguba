# Be sure to restart your server when you modify this file.
#
# This file eases your Rails 7.1 framework defaults upgrade.
#
# Uncomment each configuration one by one to switch to the new default.
# Once your application is ready to run with all new defaults, you can remove
# this file and set the `config.load_defaults` to `7.1`.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html

###
# Remove the default X-Download-Options headers since it is used only by Internet Explorer.
# If you need to support Internet Explorer, add back `"X-Download-Options" => "noopen"`.
#++
Rails.application.config.action_dispatch.default_headers = {
  "X-Frame-Options" => "SAMEORIGIN",
  "X-XSS-Protection" => "0",
  "X-Content-Type-Options" => "nosniff",
  "X-Permitted-Cross-Domain-Policies" => "none",
  "Referrer-Policy" => "strict-origin-when-cross-origin"
}

###
# Do not treat an `ActionController::Parameters` instance
# as equal to an equivalent `Hash` by default.
#++
Rails.application.config.action_controller.allow_deprecated_parameters_hash_equality = false

###
# Enable the Active Job `BigDecimal` argument serializer, which guarantees
# roundtripping. Without this serializer, some queue adapters may serialize
# `BigDecimal` arguments as simple (non-roundtrippable) strings.
#
# When deploying an application with multiple replicas, old (pre-Rails 7.1)
# replicas will not be able to deserialize `BigDecimal` arguments from this
# serializer. Therefore, this setting should only be enabled after all replicas
# have been successfully upgraded to Rails 7.1.
#++
Rails.application.config.active_job.use_big_decimal_serializer = true

###
# Specify if an `ArgumentError` should be raised if `Rails.cache` `fetch` or
# `write` are given an invalid `expires_at` or `expires_in` time.
# Options are `true`, and `false`. If `false`, the exception will be reported
# as `handled` and logged instead.
#++
Rails.application.config.active_support.raise_on_invalid_cache_expiration_time = true

###
# Enable a performance optimization that serializes message data and metadata
# together. This changes the message format, so messages serialized this way
# cannot be read by older versions of Rails. However, messages that use the old
# format can still be read, regardless of whether this optimization is enabled.
#
# To perform a rolling deploy of a Rails 7.1 upgrade, wherein servers that have
# not yet been upgraded must be able to read messages from upgraded servers,
# leave this optimization off on the first deploy, then enable it on a
# subsequent deploy.
#++
# Rails.application.config.active_support.use_message_serializer_for_metadata = true

###
# Set the maximum size for Rails log files.
#
# `config.load_defaults 7.1` does not set this value for environments other than
# development and test.
#++
# if Rails.env.local?
#   Rails.application.config.log_file_size = 100 * 1024 * 1024
# end

###
# Enable precompilation of `config.filter_parameters`. Precompilation can
# improve filtering performance, depending on the quantity and types of filters.
#++
# Rails.application.config.precompile_filter_parameters = true

###
# ** Please read carefully, this must be configured in config/application.rb **
#
# Change the format of the cache entry.
#
# Changing this default means that all new cache entries added to the cache
# will have a different format that is not supported by Rails 7.0
# applications.
#
# Only change this value after your application is fully deployed to Rails 7.1
# and you have no plans to rollback.
# When you're ready to change format, add this to `config/application.rb` (NOT
# this file):
#   config.active_support.cache_format_version = 7.1

###
# Configure Action View to use HTML5 standards-compliant sanitizers when they are supported on your
# platform.
#
# `Rails::HTML::Sanitizer.best_supported_vendor` will cause Action View to use HTML5-compliant
# sanitizers if they are supported, else fall back to HTML4 sanitizers.
#
# In previous versions of Rails, Action View always used `Rails::HTML4::Sanitizer` as its vendor.
#++
# Rails.application.config.action_view.sanitizer_vendor = Rails::HTML::Sanitizer.best_supported_vendor

###
# Configure the log level used by the DebugExceptions middleware when logging
# uncaught exceptions during requests.
#++
# Rails.application.config.action_dispatch.debug_exception_log_level = :error

###
# Configure the test helpers in Action View, Action Dispatch, and rails-dom-testing to use HTML5
# parsers.
#
# Nokogiri::HTML5 isn't supported on JRuby, so JRuby applications must set this to :html4.
#
# In previous versions of Rails, these test helpers always used an HTML4 parser.
#++
# Rails.application.config.dom_testing_default_html_version = :html5
