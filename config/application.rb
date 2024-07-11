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
require "action_cable/engine"
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
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # TODO: After upgrading load_defaults to v7.0, we will remove this line because of the default value.
    # Disables the deprecated #to_s override in some Ruby core classes
    # See https://guides.rubyonrails.org/configuring.html#config-active-support-disable-to-s-conversion for more information.
    config.active_support.disable_to_s_conversion = true
  end
end
