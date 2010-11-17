require 'test_helper'

class Ranguba::SearcherTest < ActiveSupport::TestCase

  def setup
    setup_database
  end

  def teardown
    teardown_database
  end

  def test_attributes
    searcher = Ranguba::Searcher.new
    searcher.query = "plain"
    entry = searcher.search.first
    source = @db_source[:plain]
    assert_equal source[:key], entry.title
    assert_equal source[:key], entry.url
    assert_equal source[:category], entry.category
    assert_equal source[:type], entry.type
    assert_equal source[:body], entry.body

    searcher = Ranguba::Searcher.new
    searcher.query = "html"
    entry = searcher.search.first
    source = @db_source[:html]
    assert_equal source[:title], entry.title
    assert_equal source[:key], entry.url
    assert_equal source[:category], entry.category
    assert_equal source[:type], entry.type
    assert_equal source[:body], entry.body
  end

end
