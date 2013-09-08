# -*- coding: utf-8 -*-

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'shellwords'
require 'fileutils'
require 'yaml'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  private
  # Add more helper methods to be used by all tests here...
  def run_shell_command(*args)
    command_line = Shellwords.shelljoin(args)
    result = `#{command_line} 2>&1`
  end

  def create_entries
    FactoryGirl.create(:entry, :type => "html", :type_label => "HTML")
    FactoryGirl.create(:entry, :type => "plain")
    FactoryGirl.create(:entry, :type => "css")
    FactoryGirl.create(:entry, :type => "xml")
    FactoryGirl.create(:entry, :type => "pdf", :category => "test")
    FactoryGirl.create(:entry, :type => "pdf", :category => "misc")
    FactoryGirl.create(:entry, :type => "msworddoc")
    FactoryGirl.create(:entry, :type => "vnd.ms-excel")
    FactoryGirl.create(:entry, :type => "vnd.ms-powerpoint")
    FactoryGirl.create(:entry, :type => "vnd.oasis.opendocument.text")
    FactoryGirl.create(:entry, :type => "vnd.oasis.opendocument.text-template")
    FactoryGirl.create(:entry, :type => "vnd.oasis.opendocument.spreadsheet")
    FactoryGirl.create(:entry,
                       :type => "vnd.oasis.opendocument.spreadsheet-template")
    FactoryGirl.create(:entry,
                       :type => "vnd.oasis.opendocument.presentation")
    FactoryGirl.create(:entry,
                       :type => "vnd.oasis.opendocument.presentation-template")
    FactoryGirl.create(:entry,
                       :type => "unknown",
                       :type_label => "unknown") do |entry|
      entry.body += " What is the type?"
      entry.save!
    end
    FactoryGirl.create(:entry, :type => "jxw", :title => "一太郎のドキュメント")
  end

  def setup_database
    create_entries
  end

  def teardown_database
    Ranguba::Entry.all.each(&:delete)
  end
end
