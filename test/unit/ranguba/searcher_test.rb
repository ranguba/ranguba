# -*- coding: utf-8 -*-
require 'test_helper'

class Ranguba::SearcherTest < ActiveSupport::TestCase

  def setup
    setup_database
    @searcher = Ranguba::Searcher.new
  end

  def teardown
    teardown_database
    @searcher = nil
  end

  def test_search_by_query__plain
    @searcher.query = "plain"
    entry = @searcher.search.first
    source = @db_source[:plain]
    assert_equal source[:key], entry.title
    assert_equal source[:key], entry.url
    assert_equal source[:category], entry.category
    assert_equal source[:type], entry.type
    assert_equal source[:body], entry.body
  end

  def test_search_by_query__html
    @searcher.query = "html"
    entry = @searcher.search.first
    source = @db_source[:html]
    assert_equal source[:title], entry.title
    assert_equal source[:key], entry.url
    assert_equal source[:category], entry.category
    assert_equal source[:type], entry.type
    assert_equal source[:body], entry.body
  end

  def test_search_by_query__multibyte
    @searcher.query = "一太郎"
    entry = @searcher.search.first
    encoded = SearchRequest.encode_parameter("一太郎")
    source = @db_source[:jxw]
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

  def test_search_by_category
    @searcher.category = "misc"
    entry = @searcher.search.first
    source = @db_source[:pdf2]
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
    assert_equal 1, result.n_records
  end

  def test_add_entry_and_search
    searcher = Ranguba::Searcher.new
    searcher.query = "HTML"
    assert_equal 1, searcher.search.n_records
    Ranguba::Entry.create(:key         => "http://www.example.com/another-html",
                          :title       => "Another HTML",
                          :type        => "html",
                          :encoding    => "UTF-8",
                          :category    => "test",
                          :author      => "html author",
                          :modified_at => Time.now,
                          :updated_at  => Time.now,
                          :body        => "This is the contents of another HTML entry.")
    @searcher.query = "HTML"
    assert_equal 2, @searcher.search.n_records
  end

  def test_search_by_query__not_found
    @searcher.query = "notfound"
    assert_equal 0, @searcher.search.n_records
  end

  def test_search_by_type_and_category
    searcher = Ranguba::Searcher.new(:type => "pdf", :category => "test")
    assert_equal 1, searcher.search.n_records
  end

end
