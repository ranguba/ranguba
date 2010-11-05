# coding: utf-8
require 'test_helper'

class EntryTest < ActiveSupport::TestCase
  def setup
    setup_database
    @entry = Entry.new
  end

  def teardown
    teardown_database
    @entry = nil
  end

  def test_attributes
    @entry = get_first_entry(:query => "plain")
    source = @db_source[:plain]
    assert_equal source[:url], @entry.title
    assert_equal source[:url], @entry.url
    assert_equal source[:category], @entry.category
    assert_equal source[:type], @entry.type
    assert_equal source[:body], @entry.body

    @entry = get_first_entry(:query => "html")
    source = @db_source[:html]
    assert_equal source[:title], @entry.title
    assert_equal source[:url], @entry.url
    assert_equal source[:category], @entry.category
    assert_equal source[:type], @entry.type
    assert_equal source[:body], @entry.body
  end

  def test_entry_drilldown_items
    @entry = get_first_entry(:query => "HTML")
    items = @entry.drilldown_items
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
    @entry = get_first_entry(:type => "html")
    assert_equal @entry.body[0..9]+"-", @entry.summary_by_head(options)
    assert_equal "", @entry.summary_by_query(options)
    assert_equal @entry.body[0..9]+"-", @entry.summary(options)

    # with query
    @entry = get_first_entry(:query => "HTML")
    assert_equal @entry.body[0..9]+"-", @entry.summary_by_head(options)
    assert_equal "-the[ HTML] e-",
                 @entry.summary_by_query(options)
    assert_equal "-the[ HTML] e-",
                 @entry.summary(options)
  end

  private
  def get_first_entry(options={})
    entry = get_entries(options)[0]
    assert_not_nil entry
    entry
  end

  def get_entries(options={})
    Entry.search(options)[:entries]
  end

  def assert_drilldown_item(item, options)
    assert item.is_a?(DrilldownItem)
    assert_equal options[:param], item.param
    assert_equal options[:value], item.value
    assert_equal options[:to_s], item.to_s
  end
end
