require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

require "groonga_client_model/railtie"

base_dir = File.expand_path(File.join(__dir__, ".."))
$LOAD_PATH.unshift(File.join(base_dir, "lib"))
require "ranguba/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ranguba
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Zeitwerk uses absolute file names internally, and your application should
    # not issue require calls for autoloadable files, so those directories are
    # actually not needed in $LOAD_PATH anymore.
    config.add_autoload_paths_to_load_path = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # TODO: Remove this configuration at Rails 7.2 because it will be default.
    #       Use `ActiveSupport::JSON` as the default serializer for `MessageEncryptor`
    #       and `MessageVerifier` instances.
    config.active_support.message_serializer = :json
  end
end
