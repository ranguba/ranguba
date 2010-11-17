require 'test_helper'

class Ranguba::SearcherTest < ActiveSupport::TestCase

  def setup
    setup_database
    @searcher = Ranguba::Searcher.new
  end

  def teardown
    teardown_database
  end

  def test_search_by_query
    @searcher.query = "plain"
    entry = @searcher.search.first
    source = @db_source[:plain]
    assert_equal source[:key], entry.title
    assert_equal source[:key], entry.url
    assert_equal source[:category], entry.category
    assert_equal source[:type], entry.type
    assert_equal source[:body], entry.body

    @searcher.query = "html"
    entry = @searcher.search.first
    source = @db_source[:html]
    assert_equal source[:title], entry.title
    assert_equal source[:key], entry.url
    assert_equal source[:category], entry.category
    assert_equal source[:type], entry.type
    assert_equal source[:body], entry.body
  end

  def test_search_by_type
    @searcher.type = "html"
    entry = @searcher.search.first
    source = @db_source[:html]
    assert_equal source[:title], entry.title
    assert_equal source[:key], entry.url
    assert_equal source[:category], entry.category
    assert_equal source[:type], entry.type
    assert_equal source[:body], entry.body
  end

  def test_search_class
    @searcher.query = "html"
    result = @searcher.search

    assert_instance_of Array, result.entries
    assert_instance_of Ranguba::Entry, result.first
    assert_equal 1, result.size
  end

end
