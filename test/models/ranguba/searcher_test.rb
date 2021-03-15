# -*- coding: utf-8 -*-
require 'test_helper'

class Ranguba::SearcherTest < ActiveSupport::TestCase
  setup do
    setup_database
    @searcher = Ranguba::Searcher.new
  end

  teardown do
    teardown_database
    @searcher = nil
  end

  def test_search_by_query__plain
    @searcher.query = "plain"
    titles = @searcher.search.collect(&:title)
    assert_equal(["This is a plain entry!"], titles)
  end

  def test_search_by_query__html
    @searcher.query = "html"
    titles = @searcher.search.collect(&:title)
    assert_equal(["This is a HTML entry!"], titles)
  end

  def test_search_by_query__multibyte
    @searcher.query = "一太郎"
    titles = @searcher.search.collect(&:title)
    assert_equal(["一太郎のドキュメント"], titles)
  end

  def test_search_by_type
    @searcher.type = "html"
    types = @searcher.search.collect(&:type)
    assert_equal(["html"], types)
  end

  def test_search_by_category
    @searcher.category = "misc"
    categories = @searcher.search.collect(&:category)
    assert_equal(["misc"], categories)
  end

  def test_add_entry_and_search
    searcher = Ranguba::Searcher.new
    searcher.query = "HTML"
    assert_equal(1, searcher.search.n_hits)
    Ranguba::Entry.create(:_key        => "http://www.example.com/another-html",
                          :title       => "Another HTML",
                          :type        => "html",
                          :encoding    => "UTF-8",
                          :category    => "test",
                          :author      => "html author",
                          :modified_at => Time.now,
                          :updated_at  => Time.now,
                          :body        => "This is the contents of another HTML entry.")
    @searcher.query = "HTML"
    assert_equal(2, @searcher.search.n_hits)
  end

  def test_search_by_query__not_found
    @searcher.query = "notfound"
    assert_equal(0, @searcher.search.n_hits)
  end

  def test_search_by_type_and_category
    searcher = Ranguba::Searcher.new(:type => "pdf", :category => "test")
    assert_equal(1, searcher.search.n_hits)
  end
end
