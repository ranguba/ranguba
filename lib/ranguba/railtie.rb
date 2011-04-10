module Ranguba
  class Railtie < Rails::Railtie
    # config.ranguba = ActiveSupport::OrderedOptions.new

    config.before_configuration do
      config = Rails.application.config
      case Rails.env
      when "production", "development"
        ENV["RANGUBA_LIMIT_AS"] = "2GB"
        config.index_db_path = Rails.root + "db/groonga/db"
        config.customize_base_path = Rails.root + "config/customize"

        require 'ranguba/log_path_loader'
        log_dir = Ranguba::LogPathLoader.new.load
        if log_dir
          config.paths.log = log_dir + "#{Rails.env}.log"
        end
      when "test"
        config.index_db_path = ::Rails.root + "tmp/database/db"
        config.customize_base_path = ::Rails.root + "test/fixtures/customize"
      end
    end
  end
end
