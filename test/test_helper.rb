ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'test/unit/notify'
require 'shellwords'
require 'fileutils'
require 'yaml'
require 'groonga'
ARGV.unshift("--notify")

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def run_shell_command(*args)
    command_line = Shellwords.shelljoin(args)
    result = `#{command_line} 2>&1`
  end

  def setup_database
    FileUtils.cd(::Rails.root.to_s) do
      run_shell_command("bash", "script/setup_test_db.sh")
    end
    @db = Ranguba::Database.new
    @db.open(Ranguba::Application.config.index_db_path)

    entries = Groonga["Entries"]
    source = YAML.load_file("#{::Rails.root.to_s}/test/fixtures/test_db.yml_")
    @db_source = {}
    source.each do |id, entry|
      attributes = {}
      entry.each do |key, value|
        next if key == "url"
        attributes[key.to_sym] = value
      end
      [:mtime, :update].each do |key|
        attributes[key] = Time.new(attributes[key])
      end
      entries.add(entry["url"], attributes)
      @db_source[id.to_sym] = attributes.merge(:url => entry["url"])
    end
  end

  def teardown_database
    @db.close
    @db = nil
    @db_source = nil
    FileUtils.cd(::Rails.root.to_s) do
      run_shell_command("bash", "script/teardown_test_db.sh")
    end
  end
end
