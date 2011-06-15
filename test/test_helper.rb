ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'test/unit/notify'
require 'shellwords'
require 'fileutils'
require 'yaml'
require 'groonga'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...
  def run_shell_command(*args)
    command_line = Shellwords.shelljoin(args)
    result = `#{command_line} 2>&1`
  end

  def setup_database
    source = YAML.load_file("#{::Rails.root.to_s}/test/fixtures/test_db.yml_")
    @db_source = {}
    source.each do |id, entry|
      attributes = entry.symbolize_keys
      [:modified_at, :updated_at].each do |key|
        unless attributes[key].is_a?(Time)
          attributes[key] = Time.parse(attributes[key])
        end
      end
      Ranguba::Entry.create(attributes)
      @db_source[id.to_sym] = attributes.merge(:url => entry["url"])
    end
  end

  def teardown_database
    Ranguba::Entry.select.each(&:delete)
    @db_source = nil
  end
end
