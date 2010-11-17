# -*- coding: utf-8 -*-
require 'test_helper'

class Ranguba::EntryTest < ActiveSupport::TestCase
  def setup
    setup_database
  end

  def teardown
    teardown_database
  end

  def test_entry_drilldown_items
    entry = get_first_entry(:query => "HTML")
    items = entry.drilldown_items
    assert_equal 2, items.size
    assert_drilldown_item(items[0],
                          :param => :category,
                          :value => "test",
                          :to_s => "query/HTML/category/test")
    assert_drilldown_item(items[1],
                          :param => :type,
                          :value => "html",
                          :to_s => "query/HTML/type/html")
  end

  def test_summary
    options = {:size => 10,
               :separator => "-",
               :highlight => "[%S]"}

    # without query
    entry = get_first_entry(:type => "html")
    assert_equal entry.body[0..9]+"-", entry.summary_by_head(options)
    assert_equal "", entry.summary_by_query(options)
    assert_equal entry.body[0..9]+"-", entry.summary(options)

    # with query
    entry = get_first_entry(:query => "HTML")
    assert_equal entry.body[0..9]+"-", entry.summary_by_head(options)
    assert_equal "-the[ HTML] e--text/[html].-",
                 entry.summary_by_query(options)
    assert_equal "-the[ HTML] e--text/[html].-",
                 entry.summary(options)
  end

  def test_class_table
    assert_equal Groonga::PatriciaTrie, Ranguba::Entry.table.class
  end


  def test_class_search_with_multibytes_query
    searcher = Ranguba::Searcher.new
    searcher.query = "一太郎"
    result = searcher.search
    encoded = SearchRequest.encode_parameter("一太郎")

    assert_equal Array, result[:entries].class
    assert_equal 1, result[:entries].size
    assert_equal Ranguba::Entry, result[:entries][0].class

    assert_equal Array, result[:raw_entries].class
    assert_equal 1, result[:raw_entries].size
    assert_equal Groonga::Record, result[:raw_entries][0].class

    groups = result[:drilldown_groups]
    assert_equal Hash, groups.class
    assert_equal 2, groups.size

    keys = groups.keys
    assert_equal Array, groups[keys[0]].class
    assert_equal 1, groups[keys[0]].size
    assert_drilldown_item groups[keys[0]][0],
                          :param => :category,
                          :value => "test",
                          :to_s => "query/#{encoded}/category/test"
    assert_equal Array, groups[keys[1]].class
    assert_equal 1, groups[keys[1]].size
    assert_drilldown_item groups[keys[1]][0],
                          :param => :type,
                          :value => "jxw",
                          :to_s => "query/#{encoded}/type/jxw"
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

  def assert_drilldown_item(item, options)
    assert_equal DrilldownItem, item.class
    assert_equal options[:param], item.param
    assert_equal options[:value], item.value
    assert_equal options[:to_s], item.to_s
  end
end
