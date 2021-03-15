ENV['RAILS_ENV'] ||= 'test'
require_relative "../config/environment"
require "test/unit/rails/test_help"
require "groonga_client_model/test_helper"

class ActiveSupport::TestCase
  include GroongaClientModel::TestHelper

  # Run tests in parallel with specified workers
  # parallelize(workers: :number_of_processors)

  # Add more helper methods to be used by all tests here...

  private
  def create_entries
    FactoryBot.create(:entry, :type => "html", :type_label => "HTML")
    FactoryBot.create(:entry, :type => "plain")
    FactoryBot.create(:entry, :type => "css")
    FactoryBot.create(:entry, :type => "xml")
    FactoryBot.create(:entry, :type => "pdf", :category => "test")
    FactoryBot.create(:entry, :type => "pdf", :category => "misc")
    FactoryBot.create(:entry, :type => "msworddoc")
    FactoryBot.create(:entry, :type => "vnd.ms-excel")
    FactoryBot.create(:entry, :type => "vnd.ms-powerpoint")
    FactoryBot.create(:entry, :type => "vnd.oasis.opendocument.text")
    FactoryBot.create(:entry, :type => "vnd.oasis.opendocument.text-template")
    FactoryBot.create(:entry, :type => "vnd.oasis.opendocument.spreadsheet")
    FactoryBot.create(:entry,
                       :type => "vnd.oasis.opendocument.spreadsheet-template")
    FactoryBot.create(:entry,
                       :type => "vnd.oasis.opendocument.presentation")
    FactoryBot.create(:entry,
                       :type => "vnd.oasis.opendocument.presentation-template")
    FactoryBot.create(:entry,
                       :type => "unknown",
                       :type_label => "unknown") do |entry|
      entry.body += " What is the type?"
      entry.save!
    end
    FactoryBot.create(:entry, :type => "jxw", :title => "一太郎のドキュメント")
  end

  def setup_database
    create_entries
  end

  def teardown_database
  end
end
