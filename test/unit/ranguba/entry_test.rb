# -*- coding: utf-8 -*-
require 'test_helper'

class Ranguba::EntryTest < ActiveSupport::TestCase
  def setup
    setup_database
  end

  def teardown
    teardown_database
  end

  def test_summary_with_query
    options = {:size => 10,
               :separator => "-",
               :highlight => "[%S]"}
    searcher = Ranguba::Searcher.new
    searcher.query = "HTML"
    resultset = searcher.search
    entry = resultset.first

    assert_equal entry.body[0..9]+"-", entry.summary_by_head(options)
    assert_equal "-the[ HTML] e--text/[html].-",
                 entry.summary_by_query(resultset.expression, options)
    assert_equal "-the[ HTML] e--text/[html].-",
                 entry.summary(resultset.expression, options)
  end

  def test_summary_without_query
    options = {:size => 10,
               :separator => "-",
               :highlight => "[%S]"}
    searcher = Ranguba::Searcher.new
    searcher.type = "html"
    resultset = searcher.search
    entry = resultset.first

    assert_equal entry.body[0..9]+"-", entry.summary_by_head(options)
    assert_equal "", entry.summary_by_query(resultset.expression, options)
    assert_equal entry.body[0..9]+"-", entry.summary(resultset.expression, options)
  end

  def test_class_table
    assert_equal Groonga::PatriciaTrie, Ranguba::Entry.table.class
  end

  private
  def get_first_entry(options={})
    searcher = Ranguba::Searcher.new
    searcher.query = options[:query]
    entry = searcher.search.first
    assert_not_nil entry
    entry
  end

  def get_entries(options={})
    searcher = Ranguba::Searcher.new
    searcher.query = options[:query]
    searcher.search.all
  end

end
