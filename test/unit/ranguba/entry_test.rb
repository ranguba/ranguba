# coding: utf-8
require 'test_helper'

class Ranguba::EntryTest < ActiveSupport::TestCase
  def setup
    setup_database
  end

  def teardown
    teardown_database
  end

  def test_attributes
    entry = get_first_entry(:query => "plain")
    source = @db_source[:plain]
    assert_equal source[:url], entry.title
    assert_equal source[:url], entry.url
    assert_equal source[:category], entry.category
    assert_equal source[:type], entry.type
    assert_equal source[:body], entry.body

    entry = get_first_entry(:query => "html")
    source = @db_source[:html]
    assert_equal source[:title], entry.title
    assert_equal source[:url], entry.url
    assert_equal source[:category], entry.category
    assert_equal source[:type], entry.type
    assert_equal source[:body], entry.body
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
    assert_equal Groonga::Hash, Ranguba::Entry.table.class
  end

  def test_class_search
    result = Ranguba::Entry.search(:query => "HTML")

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
                          :to_s => "query/HTML/category/test"
    assert_equal Array, groups[keys[1]].class
    assert_equal 1, groups[keys[1]].size
    assert_drilldown_item groups[keys[1]][0],
                          :param => :type,
                          :value => "html",
                          :to_s => "query/HTML/type/html"
  end

  def test_class_search_with_multibytes_query
    result = Ranguba::Entry.search(:query => "一太郎")
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

  def test_class_add
    result = Ranguba::Entry.search(:query => "HTML")
    assert_equal 1, result[:entries].size
    Ranguba::Entry.add("http://www.example.com/another-html",
                       :title => "Another HTML",
                       :type => "html",
                       :charset => "UTF-8",
                       :category => "test",
                       :author => "html author",
                       :mtime => Time.now,
                       :update => Time.now,
                       :body => "This is the contents of another HTML entry.")
    result = Ranguba::Entry.search(:query => "HTML")
    assert_equal 2, result[:entries].size
  end

  private
  def get_first_entry(options={})
    entry = get_entries(options)[0]
    assert_not_nil entry
    entry
  end

  def get_entries(options={})
    Ranguba::Entry.search(options)[:entries]
  end

  def assert_drilldown_item(item, options)
    assert_equal DrilldownItem, item.class
    assert_equal options[:param], item.param
    assert_equal options[:value], item.value
    assert_equal options[:to_s], item.to_s
  end
end
